#!/bin/bash
# Complete cleanup script for LocalStack volume issues

echo "========================================="
echo "Complete Cleanup of ECS Prototype"
echo "========================================="
echo ""
echo "This will remove ALL containers, volumes, and cached data."
echo "Press Ctrl+C to cancel, or Enter to continue..."
read

cd "$(dirname "$0")/.."

echo ""
echo "Step 1: Stopping all containers..."
docker-compose down 2>/dev/null || true
docker-compose -f docker-compose.simple.yml down 2>/dev/null || true

echo ""
echo "Step 2: Removing specific containers..."
docker rm -f localstack sample-app jenkins aws-cli 2>/dev/null || true

echo ""
echo "Step 3: Removing volumes..."
docker volume rm ecs-prototype_localstack-data 2>/dev/null || true
docker volume rm ecs-prototype_jenkins-data 2>/dev/null || true

echo ""
echo "Step 4: Removing networks..."
docker network rm ecs-prototype_ecs-network 2>/dev/null || true

echo ""
echo "Step 5: Pruning system (removing dangling volumes)..."
docker volume prune -f

echo ""
echo "Step 6: Removing any orphaned mounts..."
# Check if there are any bind mounts to localstack data
docker ps -a | grep localstack && docker rm -f $(docker ps -a | grep localstack | awk '{print $1}') 2>/dev/null || true

echo ""
echo "========================================="
echo "Cleanup Complete!"
echo "========================================="
echo ""
echo "Now you can start fresh with:"
echo "  docker-compose up -d"
echo ""
echo "Or rebuild images first:"
echo "  docker-compose build --no-cache"
echo "  docker-compose up -d"
echo "========================================="
