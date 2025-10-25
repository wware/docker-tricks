#!/bin/bash
# Reset the ECS prototype environment (removes all data)

set -e

echo "========================================="
echo "Resetting ECS Prototype Environment"
echo "========================================="
echo ""
echo "WARNING: This will remove all containers, volumes, and data!"
echo "Press Ctrl+C to cancel, or Enter to continue..."
read

# Navigate to the script directory
cd "$(dirname "$0")/.."

# Stop and remove everything
echo "Stopping services..."
docker-compose down -v

echo ""
echo "========================================="
echo "Environment Reset Complete!"
echo "========================================="
echo ""
echo "All containers, networks, and volumes have been removed."
echo ""
echo "To start fresh:"
echo "  ./scripts/start.sh"
echo "========================================="
