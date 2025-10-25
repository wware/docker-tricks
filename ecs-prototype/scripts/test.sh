#!/bin/bash
# Test the ECS prototype environment

set -e

echo "========================================="
echo "Testing ECS Prototype Environment"
echo "========================================="

# Navigate to the script directory
cd "$(dirname "$0")/.."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Function to test an endpoint
test_endpoint() {
    local name=$1
    local url=$2
    local expected_code=${3:-200}

    echo -n "Testing $name... "

    response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>&1)

    if [ "$response" = "$expected_code" ]; then
        echo -e "${GREEN}PASS${NC} (HTTP $response)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAIL${NC} (Expected HTTP $expected_code, got $response)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Function to test AWS CLI
test_aws_cli() {
    local name=$1
    local command=$2

    echo -n "Testing $name... "

    if docker-compose exec -T aws-cli $command > /dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAIL${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

echo ""
echo "1. Testing Sample Application Endpoints"
echo "----------------------------------------"
test_endpoint "Health Check" "http://localhost:8080/health"
test_endpoint "Main Endpoint" "http://localhost:8080/"
test_endpoint "Config Endpoint" "http://localhost:8080/config"
test_endpoint "Secret Endpoint" "http://localhost:8080/secret"
test_endpoint "Info Endpoint" "http://localhost:8080/info"

echo ""
echo "2. Testing LocalStack Services"
echo "----------------------------------------"
test_endpoint "LocalStack Health" "http://localhost:4566/_localstack/health"

echo ""
echo "3. Testing AWS CLI Access"
echo "----------------------------------------"
test_aws_cli "ECS Cluster List" "aws --endpoint-url=http://localstack:4566 ecs list-clusters --region us-east-1"
test_aws_cli "Parameter Store Access" "aws --endpoint-url=http://localstack:4566 ssm get-parameter --name /myapp/config/environment --region us-east-1"
test_aws_cli "Secrets Manager Access" "aws --endpoint-url=http://localstack:4566 secretsmanager get-secret-value --secret-id myapp/database/password --region us-east-1"
test_aws_cli "Load Balancer List" "aws --endpoint-url=http://localstack:4566 elbv2 describe-load-balancers --region us-east-1"

echo ""
echo "========================================="
echo "Test Results"
echo "========================================="
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo "Total Tests:  $((TESTS_PASSED + TESTS_FAILED))"
echo "========================================="

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi
