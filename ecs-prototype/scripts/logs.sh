#!/bin/bash
# View logs from the ECS prototype environment

# Navigate to the script directory
cd "$(dirname "$0")/.."

# Check if a service name was provided
if [ -n "$1" ]; then
    echo "========================================="
    echo "Viewing logs for: $1"
    echo "========================================="
    echo "Press Ctrl+C to exit"
    echo ""
    docker-compose logs -f "$1"
else
    echo "========================================="
    echo "Viewing logs for all services"
    echo "========================================="
    echo "Press Ctrl+C to exit"
    echo ""
    echo "Available services:"
    echo "  - localstack"
    echo "  - sample-app"
    echo "  - jenkins"
    echo "  - aws-cli"
    echo ""
    echo "To view logs for a specific service:"
    echo "  ./scripts/logs.sh <service-name>"
    echo ""
    echo "Showing all logs:"
    echo "========================================="
    echo ""
    docker-compose logs -f
fi
