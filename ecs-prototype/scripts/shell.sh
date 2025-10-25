#!/bin/bash
# Open a shell in a container

# Navigate to the script directory
cd "$(dirname "$0")/.."

# Default to aws-cli if no service specified
SERVICE=${1:-aws-cli}

echo "========================================="
echo "Opening shell in: $SERVICE"
echo "========================================="
echo ""

if [ "$SERVICE" = "aws-cli" ]; then
    echo "AWS CLI is pre-configured for LocalStack"
    echo ""
    echo "Try these commands:"
    echo "  aws --endpoint-url=http://localstack:4566 ecs list-clusters"
    echo "  aws --endpoint-url=http://localstack:4566 ssm get-parameter --name /myapp/config/environment"
    echo "  aws --endpoint-url=http://localstack:4566 secretsmanager list-secrets"
    echo ""
fi

docker-compose exec "$SERVICE" sh
