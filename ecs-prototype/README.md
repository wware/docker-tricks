# ECS Prototype Environment

A local development environment that mimics AWS ECS, complete with Application Load Balancer, Parameter Store, Secrets Manager, and Jenkins for testing deployment pipelines.

## Overview

This setup allows you to prototype and test ECS deployments locally before pushing to production. It uses LocalStack to emulate AWS services and provides a complete environment for developing and debugging ECS applications and deployment scripts.

## What's Included

- **LocalStack**: Emulates AWS services (ECS, ECR, ALB, SSM Parameter Store, Secrets Manager, IAM, CloudWatch)
- **Sample Application**: A Flask-based web service that demonstrates accessing AWS services
- **Jenkins**: For testing CI/CD pipelines
- **AWS CLI Container**: Pre-configured for manual testing
- **Helper Scripts**: To simplify common operations

## Architecture

```
┌───────────────────────────────────────────────────────────┐
│                     Docker Network                        │
│                                                           │
│  ┌──────────────┐       ┌──────────────┐                  │
│  │              │       │              │                  │
│  │  LocalStack  │◄──────│  Sample App  │                  │
│  │              │       │              │                  │
│  │  - ECS       │       │  - Flask     │                  │
│  │  - ALB       │       │  - boto3     │                  │
│  │  - Parameter │       │              │                  │
│  │    Store     │       │              │                  │
│  │  - Secrets   │       │              │                  │
│  │    Manager   │       └──────────────┘                  │
│  │  - ECR       │                                         │
│  │  - IAM       │       ┌──────────────┐                  │
│  └──────────────┘       │              │                  │
│         ▲               │   Jenkins    │                  │
│         │               │              │                  │
│         │               │  - Pipelines │                  │
│         └───────────────┤  - Deploy    │                  │
│                         │    Scripts   │                  │
│                         └──────────────┘                  │
└───────────────────────────────────────────────────────────┘
```

## Prerequisites

- Docker and Docker Compose
- At least 4GB of RAM available for Docker
- Ports 4566, 8080, 8081 available

## Quick Start

### 1. Start the Environment

```bash
cd ecs-prototype
docker-compose up -d
```

This will:
- Start LocalStack with AWS service emulation
- Initialize ECS cluster, ALB, Parameter Store, and Secrets Manager
- Start the sample application
- Start Jenkins (optional)

### 2. Verify Services are Running

```bash
# Check all containers are healthy
docker-compose ps

# Check LocalStack health
curl http://localhost:4566/_localstack/health
```

### 3. Test the Sample Application

```bash
# Health check
curl http://localhost:8080/health

# Main endpoint
curl http://localhost:8080/

# Get config from Parameter Store
curl http://localhost:8080/config

# Get secret from Secrets Manager
curl http://localhost:8080/secret

# View environment info
curl http://localhost:8080/info
```

### 4. Access Services

- **Sample App**: http://localhost:8080
- **Jenkins**: http://localhost:8081
- **LocalStack**: http://localhost:4566

## Testing ECS Deployments

### Using the AWS CLI Container

The setup includes an AWS CLI container pre-configured to work with LocalStack:

```bash
# Enter the AWS CLI container
docker-compose exec aws-cli sh

# List ECS clusters
aws --endpoint-url=http://localstack:4566 ecs list-clusters

# Describe the cluster
aws --endpoint-url=http://localstack:4566 ecs describe-clusters \
    --clusters sample-app-cluster

# List services
aws --endpoint-url=http://localstack:4566 ecs list-services \
    --cluster sample-app-cluster

# View Parameter Store parameters
aws --endpoint-url=http://localstack:4566 ssm get-parameter \
    --name /myapp/config/environment

# View secrets
aws --endpoint-url=http://localstack:4566 secretsmanager get-secret-value \
    --secret-id myapp/database/password

# List load balancers
aws --endpoint-url=http://localstack:4566 elbv2 describe-load-balancers
```

### Using the Deployment Script

A standalone deployment script is provided that mimics a typical Jenkins deployment:

```bash
# From the host (outside containers)
cd ecs-prototype
docker-compose exec aws-cli sh -c "cd /var/jenkins_home/pipelines && ./deploy-script.sh"
```

### Testing Jenkins Pipelines

1. Access Jenkins at http://localhost:8081
2. Create a new Pipeline job
3. Point it to `jenkins/Jenkinsfile.example`
4. Run the pipeline to test your deployment process

## Customizing for Your Use Case

### Adding Your Own Application

1. Replace the `sample-app` directory with your application
2. Update the `docker-compose.yml` to use your application's Dockerfile
3. Modify environment variables as needed

### Adding More AWS Resources

Edit `localstack-init/01-setup-resources.sh` to add:
- More SSM parameters
- Additional secrets
- RDS databases
- S3 buckets
- SNS topics
- SQS queues
- DynamoDB tables

### Modifying the Jenkins Pipeline

The `jenkins/Jenkinsfile.example` demonstrates a complete ECS deployment flow:
1. Build Docker image
2. Push to ECR (emulated)
3. Register ECS task definition
4. Update/create ECS service
5. Verify deployment

Customize this for your specific deployment process.

## Project Structure

```
ecs-prototype/
├── docker-compose.yml              # Main orchestration file
├── docker-compose.simple.yml       # Simplified version (no health checks)
├── README.md                       # This file
├── sample-app/                     # Sample application
│   ├── Dockerfile
│   ├── app.py                      # Flask application
│   └── requirements.txt
├── localstack-init/                # LocalStack initialization
│   └── 01-setup-resources.sh       # Creates AWS resources
├── jenkins/                        # Jenkins configuration
│   ├── Jenkinsfile.example         # Example pipeline
│   └── deploy-script.sh            # Standalone deploy script
└── scripts/                        # Helper scripts
    ├── start.sh                    # Start environment
    ├── stop.sh                     # Stop environment
    ├── logs.sh                     # View logs
    ├── test.sh                     # Test environment
    ├── shell.sh                    # Open shell in container
    └── reset.sh                    # Reset environment
```

## Common Operations

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f localstack
docker-compose logs -f sample-app

# Or use the helper script
./scripts/logs.sh
```

### Reset the Environment

```bash
# Stop and remove all containers and volumes
docker-compose down -v

# Start fresh
docker-compose up -d
```

### Update Resources

After modifying `localstack-init/01-setup-resources.sh`:

```bash
# Restart LocalStack to re-run initialization
docker-compose restart localstack

# Or do a full reset
docker-compose down -v
docker-compose up -d
```

## Troubleshooting

### Container Health Check Failures

If you see errors like "Container is unhealthy" when running `docker-compose up`:

```bash
# Check which container is unhealthy
docker-compose ps

# View detailed logs for the unhealthy container
docker-compose logs localstack
docker-compose logs sample-app

# Try the simplified compose file without strict health checks
docker-compose -f docker-compose.simple.yml up -d

# Or start services individually
docker-compose up -d localstack
# Wait 30-60 seconds for LocalStack to fully start
docker-compose up -d sample-app jenkins aws-cli
```

**Common causes:**
- LocalStack takes longer than expected to start (needs 30-60 seconds)
- Docker resources are constrained (needs 4GB+ RAM)
- Port 4566 is already in use

### LocalStack Not Starting

```bash
# Check logs
docker-compose logs localstack

# Ensure ports are available
lsof -i :4566

# Increase Docker resources (needs 4GB+ RAM)

# Check if LocalStack is actually responding (even if marked unhealthy)
curl http://localhost:4566/_localstack/health
```

### Sample App Can't Connect to LocalStack

```bash
# Check network connectivity
docker-compose exec sample-app ping localstack

# Verify LocalStack is healthy
curl http://localhost:4566/_localstack/health

# Check environment variables
docker-compose exec sample-app env | grep AWS
```

### AWS Resources Not Created

```bash
# Check init script logs
docker-compose logs localstack | grep "setup-resources"

# Manually run the script
docker-compose exec localstack sh /etc/localstack/init/ready.d/01-setup-resources.sh

# Check resource IDs
docker-compose exec localstack cat /tmp/localstack/resource-ids.txt
```

### Jenkins Pipeline Fails

```bash
# Check Jenkins logs
docker-compose logs jenkins

# Verify AWS CLI access from Jenkins
docker-compose exec jenkins aws --endpoint-url=http://localstack:4566 ecs list-clusters

# Check Docker socket access
docker-compose exec jenkins docker ps
```

## Differences from Production ECS

### What's Similar
- Task definitions and service configurations
- Parameter Store and Secrets Manager access patterns
- AWS CLI commands and SDK usage
- IAM role configurations (basic)
- Load balancer concepts

### What's Different
- LocalStack's ECS is a simplified implementation
- No true Fargate - containers run in Docker Compose
- Networking model is Docker networking, not AWS VPC
- IAM policies are less strict
- No actual AWS costs or quotas
- Some advanced ECS features may not work

## Best Practices

1. **Use this for development and testing**, not as a production substitute
2. **Test your deploy scripts here** before running in production
3. **Keep IAM policies realistic** even though LocalStack is permissive
4. **Use the same AWS CLI commands** you'd use in production
5. **Document differences** you discover between LocalStack and real AWS

## Advanced Usage

### Running ECS Tasks Manually

```bash
# Register a task definition
aws --endpoint-url=http://localhost:4566 ecs register-task-definition \
    --cli-input-json file://task-def.json

# Run a one-off task
aws --endpoint-url=http://localhost:4566 ecs run-task \
    --cluster sample-app-cluster \
    --task-definition sample-app-task \
    --launch-type FARGATE
```

### Testing with Different Parameter Store Values

```bash
# Update a parameter
aws --endpoint-url=http://localhost:4566 ssm put-parameter \
    --name /myapp/config/environment \
    --value "testing" \
    --overwrite

# Restart your app to pick up changes
docker-compose restart sample-app
```

### Simulating Secrets Rotation

```bash
# Update a secret
aws --endpoint-url=http://localhost:4566 secretsmanager update-secret \
    --secret-id myapp/database/password \
    --secret-string "new-password-456"

# Your app would need to refresh the secret
```

## Resources

- [LocalStack Documentation](https://docs.localstack.cloud/)
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [AWS CLI Reference](https://docs.aws.amazon.com/cli/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

## Contributing

This is a prototype environment. Feel free to:
- Add more AWS service examples
- Improve the Jenkins pipeline
- Add more helper scripts
- Document additional use cases

## License

This example is provided as-is for educational and development purposes.
