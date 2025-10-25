#!/bin/bash
# Standalone deployment script for ECS
# This can be run from Jenkins or locally for testing

set -e

# Configuration
AWS_REGION=${AWS_DEFAULT_REGION:-us-east-1}
AWS_ENDPOINT=${AWS_ENDPOINT_URL:-http://localstack:4566}
CLUSTER_NAME=${ECS_CLUSTER:-sample-app-cluster}
SERVICE_NAME=${ECS_SERVICE:-sample-app-service}
TASK_FAMILY=${TASK_FAMILY:-sample-app-task}
IMAGE_NAME=${IMAGE_NAME:-sample-app}
IMAGE_TAG=${IMAGE_TAG:-latest}

echo "========================================="
echo "ECS Deployment Script"
echo "========================================="
echo "Region: $AWS_REGION"
echo "Cluster: $CLUSTER_NAME"
echo "Service: $SERVICE_NAME"
echo "Task: $TASK_FAMILY"
echo "Image: $IMAGE_NAME:$IMAGE_TAG"
echo "========================================="

# Function to check if running in LocalStack
is_localstack() {
    [[ "$AWS_ENDPOINT" == *"localstack"* ]] || [[ "$AWS_ENDPOINT" == *"localhost:4566"* ]]
}

# Build the Docker image
echo "Step 1: Building Docker image..."
docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ./sample-app
docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest
echo "Image built successfully!"

# Push to ECR (if using real AWS, this would include login)
if is_localstack; then
    echo "Step 2: Setting up LocalStack ECR..."
    aws --endpoint-url=${AWS_ENDPOINT} ecr create-repository \
        --repository-name ${IMAGE_NAME} \
        --region ${AWS_REGION} 2>/dev/null || echo "Repository already exists"
else
    echo "Step 2: Logging into AWS ECR..."
    aws ecr get-login-password --region ${AWS_REGION} | \
        docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
fi

# Register task definition
echo "Step 3: Registering ECS task definition..."
TASK_DEF_ARN=$(aws ${AWS_ENDPOINT:+--endpoint-url=$AWS_ENDPOINT} ecs register-task-definition \
    --family ${TASK_FAMILY} \
    --network-mode awsvpc \
    --requires-compatibilities FARGATE \
    --cpu 256 \
    --memory 512 \
    --execution-role-arn arn:aws:iam::000000000000:role/ecsTaskExecutionRole \
    --container-definitions "[
        {
            \"name\": \"${IMAGE_NAME}\",
            \"image\": \"${IMAGE_NAME}:${IMAGE_TAG}\",
            \"portMappings\": [{\"containerPort\": 8080, \"protocol\": \"tcp\"}],
            \"environment\": [
                {\"name\": \"AWS_DEFAULT_REGION\", \"value\": \"${AWS_REGION}\"},
                {\"name\": \"AWS_ENDPOINT_URL\", \"value\": \"${AWS_ENDPOINT}\"}
            ],
            \"logConfiguration\": {
                \"logDriver\": \"awslogs\",
                \"options\": {
                    \"awslogs-group\": \"/ecs/${IMAGE_NAME}\",
                    \"awslogs-region\": \"${AWS_REGION}\",
                    \"awslogs-stream-prefix\": \"ecs\"
                }
            }
        }
    ]" \
    --region ${AWS_REGION} \
    --query 'taskDefinition.taskDefinitionArn' \
    --output text)

echo "Task definition registered: $TASK_DEF_ARN"

# Deploy to ECS
echo "Step 4: Deploying to ECS..."

# Check if service exists
SERVICE_EXISTS=$(aws ${AWS_ENDPOINT:+--endpoint-url=$AWS_ENDPOINT} ecs describe-services \
    --cluster ${CLUSTER_NAME} \
    --services ${SERVICE_NAME} \
    --region ${AWS_REGION} \
    --query 'services[0].serviceName' \
    --output text 2>/dev/null || echo "None")

if [ "$SERVICE_EXISTS" != "None" ] && [ "$SERVICE_EXISTS" != "" ]; then
    echo "Updating existing service..."
    aws ${AWS_ENDPOINT:+--endpoint-url=$AWS_ENDPOINT} ecs update-service \
        --cluster ${CLUSTER_NAME} \
        --service ${SERVICE_NAME} \
        --task-definition ${TASK_FAMILY} \
        --force-new-deployment \
        --region ${AWS_REGION}
else
    echo "Creating new service..."
    # Note: In real deployment, you'd specify subnets and security groups here
    aws ${AWS_ENDPOINT:+--endpoint-url=$AWS_ENDPOINT} ecs create-service \
        --cluster ${CLUSTER_NAME} \
        --service-name ${SERVICE_NAME} \
        --task-definition ${TASK_FAMILY} \
        --desired-count 1 \
        --launch-type FARGATE \
        --region ${AWS_REGION}
fi

echo "========================================="
echo "Deployment complete!"
echo "========================================="

# Show service status
echo "Service status:"
aws ${AWS_ENDPOINT:+--endpoint-url=$AWS_ENDPOINT} ecs describe-services \
    --cluster ${CLUSTER_NAME} \
    --services ${SERVICE_NAME} \
    --region ${AWS_REGION} \
    --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount}' \
    --output table

echo ""
echo "To check logs:"
echo "  aws ${AWS_ENDPOINT:+--endpoint-url=$AWS_ENDPOINT} logs tail /ecs/${IMAGE_NAME} --follow"
