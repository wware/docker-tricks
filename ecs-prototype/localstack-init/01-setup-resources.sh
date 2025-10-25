#!/bin/bash

# This script runs when LocalStack is ready
# It sets up ECS, Parameter Store, Secrets Manager, and ALB resources

set -e

echo "========================================="
echo "Setting up LocalStack AWS resources..."
echo "========================================="

REGION=us-east-1
ENDPOINT=http://localhost:4566

# Create SSM Parameters
echo "Creating SSM Parameter Store parameters..."
awslocal ssm put-parameter \
    --name "/myapp/config/environment" \
    --value "local-development" \
    --type "String" \
    --region $REGION

awslocal ssm put-parameter \
    --name "/myapp/config/app-name" \
    --value "sample-ecs-app" \
    --type "String" \
    --region $REGION

awslocal ssm put-parameter \
    --name "/myapp/config/log-level" \
    --value "DEBUG" \
    --type "String" \
    --region $REGION

echo "SSM parameters created successfully!"

# Create Secrets Manager secrets
echo "Creating Secrets Manager secrets..."
awslocal secretsmanager create-secret \
    --name "myapp/database/password" \
    --secret-string "super-secret-password-123" \
    --region $REGION

awslocal secretsmanager create-secret \
    --name "myapp/api/key" \
    --secret-string "api-key-abc-xyz-789" \
    --region $REGION

echo "Secrets Manager secrets created successfully!"

# Create VPC and subnets for ECS
echo "Creating VPC and networking resources..."
VPC_ID=$(awslocal ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --region $REGION \
    --query 'Vpc.VpcId' \
    --output text)

echo "VPC created: $VPC_ID"

# Create Internet Gateway
IGW_ID=$(awslocal ec2 create-internet-gateway \
    --region $REGION \
    --query 'InternetGateway.InternetGatewayId' \
    --output text)

awslocal ec2 attach-internet-gateway \
    --vpc-id $VPC_ID \
    --internet-gateway-id $IGW_ID \
    --region $REGION

# Create subnets
SUBNET1_ID=$(awslocal ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 10.0.1.0/24 \
    --availability-zone ${REGION}a \
    --region $REGION \
    --query 'Subnet.SubnetId' \
    --output text)

SUBNET2_ID=$(awslocal ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 10.0.2.0/24 \
    --availability-zone ${REGION}b \
    --region $REGION \
    --query 'Subnet.SubnetId' \
    --output text)

echo "Subnets created: $SUBNET1_ID, $SUBNET2_ID"

# Create security group
SG_ID=$(awslocal ec2 create-security-group \
    --group-name ecs-sample-sg \
    --description "Security group for ECS sample app" \
    --vpc-id $VPC_ID \
    --region $REGION \
    --query 'GroupId' \
    --output text)

awslocal ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 8080 \
    --cidr 0.0.0.0/0 \
    --region $REGION

awslocal ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0 \
    --region $REGION

echo "Security group created: $SG_ID"

# Create ECS cluster
echo "Creating ECS cluster..."
awslocal ecs create-cluster \
    --cluster-name sample-app-cluster \
    --region $REGION

echo "ECS cluster created successfully!"

# Create ALB
echo "Creating Application Load Balancer..."
ALB_ARN=$(awslocal elbv2 create-load-balancer \
    --name sample-app-alb \
    --subnets $SUBNET1_ID $SUBNET2_ID \
    --security-groups $SG_ID \
    --scheme internet-facing \
    --region $REGION \
    --query 'LoadBalancers[0].LoadBalancerArn' \
    --output text)

echo "ALB created: $ALB_ARN"

# Create target group
TG_ARN=$(awslocal elbv2 create-target-group \
    --name sample-app-tg \
    --protocol HTTP \
    --port 8080 \
    --vpc-id $VPC_ID \
    --health-check-path /health \
    --region $REGION \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)

echo "Target group created: $TG_ARN"

# Create listener
awslocal elbv2 create-listener \
    --load-balancer-arn $ALB_ARN \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=forward,TargetGroupArn=$TG_ARN \
    --region $REGION

echo "Listener created successfully!"

# Create IAM role for ECS tasks
echo "Creating IAM roles..."
awslocal iam create-role \
    --role-name ecsTaskExecutionRole \
    --assume-role-policy-document '{
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Principal": {"Service": "ecs-tasks.amazonaws.com"},
            "Action": "sts:AssumeRole"
        }]
    }' \
    --region $REGION

# Attach policies
awslocal iam put-role-policy \
    --role-name ecsTaskExecutionRole \
    --policy-name ecsTaskExecutionPolicy \
    --policy-document '{
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "ssm:GetParameters",
                "ssm:GetParameter",
                "secretsmanager:GetSecretValue"
            ],
            "Resource": "*"
        }]
    }' \
    --region $REGION

echo "IAM roles created successfully!"

# Save resource IDs to a file for reference
cat > /tmp/localstack/resource-ids.txt <<EOF
VPC_ID=$VPC_ID
SUBNET1_ID=$SUBNET1_ID
SUBNET2_ID=$SUBNET2_ID
SG_ID=$SG_ID
ALB_ARN=$ALB_ARN
TG_ARN=$TG_ARN
EOF

echo "========================================="
echo "LocalStack resources setup complete!"
echo "========================================="
echo "Resource IDs saved to /tmp/localstack/resource-ids.txt"
echo ""
echo "Summary:"
echo "  - VPC: $VPC_ID"
echo "  - Subnets: $SUBNET1_ID, $SUBNET2_ID"
echo "  - Security Group: $SG_ID"
echo "  - ECS Cluster: sample-app-cluster"
echo "  - ALB: $ALB_ARN"
echo "  - Target Group: $TG_ARN"
echo "  - SSM Parameters: 3 created"
echo "  - Secrets: 2 created"
echo "========================================="
