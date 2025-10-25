#!/bin/bash
# Stop the ECS prototype environment

set -e

echo "========================================="
echo "Stopping ECS Prototype Environment"
echo "========================================="

# Navigate to the script directory
cd "$(dirname "$0")/.."

# Stop services
docker-compose stop

echo ""
echo "========================================="
echo "Environment Stopped!"
echo "========================================="
echo ""
echo "To start again:"
echo "  ./scripts/start.sh"
echo ""
echo "To completely remove (including volumes):"
echo "  ./scripts/reset.sh"
echo "========================================="
