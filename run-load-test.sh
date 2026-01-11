#!/bin/bash

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Adminer Load Test ===${NC}"

# Check if k6 is installed
if ! command -v k6 &> /dev/null; then
    echo "k6 is not installed. Installing via Homebrew..."
    brew install k6
fi

# Ensure services are running
echo "Checking if services are running..."
if ! docker-compose ps | grep -q "Up"; then
    echo "Starting Docker Compose services..."
    docker-compose up -d
    echo "Waiting for services to be ready..."
    sleep 15
fi

# Run the load test
echo -e "${GREEN}Running k6 load test...${NC}"
k6 run --out json=load-test-results.json load-test.js

echo ""
echo -e "${GREEN}=== Load Test Complete ===${NC}"
echo "Results saved to: load-test-results.json"
echo ""
echo "To view detailed results, you can:"
echo "  1. Check the console output above"
echo "  2. Analyze load-test-results.json"
echo "  3. Use k6 cloud or other visualization tools"
