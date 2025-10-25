#!/bin/bash
# Start the ECS prototype environment

set -e

echo "========================================="
echo "Starting ECS Prototype Environment"
echo "========================================="

# Navigate to the script directory
cd "$(dirname "$0")/.."

# Start services
echo "Starting Docker Compose services..."
docker-compose up -d

echo ""
echo "Waiting for services to be healthy..."
sleep 5

# Check service health
echo ""
echo "Service Status:"
docker-compose ps

echo ""
echo "========================================="
echo "Environment Started!"
echo "========================================="
echo ""
echo "Services available at:"
echo "  - Sample App:  http://localhost:8080"
echo "  - Jenkins:     http://localhost:8081"
echo "  - LocalStack:  http://localhost:4566"
echo ""
echo "Quick test:"
echo "  curl http://localhost:8080/health"
echo ""
echo "To view logs:"
echo "  ./scripts/logs.sh"
echo ""
echo "To stop:"
echo "  ./scripts/stop.sh"
echo "========================================="
