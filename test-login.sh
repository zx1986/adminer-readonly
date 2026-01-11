#!/bin/bash

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Adminer Login Test ===${NC}"

# Start services
echo "Starting Docker Compose services..."
docker-compose up -d

# Wait for services to be ready
echo "Waiting for services to be ready..."
sleep 10

# Check if Adminer is accessible
MAX_RETRIES=30
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200"; then
        echo -e "${GREEN}✓ Adminer is ready${NC}"
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "Waiting for Adminer... ($RETRY_COUNT/$MAX_RETRIES)"
    sleep 2
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo -e "${RED}✗ Adminer failed to start${NC}"
    docker-compose logs adminer
    exit 1
fi

# Additional wait for MariaDB to be fully ready
echo "Waiting for MariaDB to be ready..."
sleep 5

# Verify MariaDB is accepting connections
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if docker-compose exec -T mariadb mysqladmin ping -h localhost -u root -pexample 2>/dev/null | grep -q "mysqld is alive"; then
        echo -e "${GREEN}✓ MariaDB is ready${NC}"
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "Waiting for MariaDB... ($RETRY_COUNT/$MAX_RETRIES)"
    sleep 2
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo -e "${RED}✗ MariaDB failed to start${NC}"
    docker-compose logs mariadb
    exit 1
fi

# Test login with predefined credentials
echo "Testing login with predefined credentials (adminer/adminer)..."

# Get the login page to extract CSRF token and session cookies
COOKIE_JAR=$(mktemp)
LOGIN_PAGE=$(curl -s -c $COOKIE_JAR http://localhost:8080)

# Extract CSRF token from the login page
TOKEN=$(echo "$LOGIN_PAGE" | grep -o "name='token' value='[^']*'" | sed "s/name='token' value='//;s/'//")

if [ -z "$TOKEN" ]; then
    echo -e "${RED}✗ Failed to extract CSRF token${NC}"
    TEST_RESULT=1
else
    echo "CSRF token extracted: $TOKEN"
    
    # Attempt login with the predefined credentials
    # The login-predefined plugin uses "predefined" as placeholder values
    # Server should be "mariadb" as configured in ADMINER_DEFAULT_SERVER
    LOGIN_RESPONSE=$(curl -s -L -b $COOKIE_JAR -c $COOKIE_JAR \
        -d "auth[driver]=server" \
        -d "auth[server]=mariadb" \
        -d "auth[username]=predefined" \
        -d "auth[password]=predefined" \
        -d "auth[db]=" \
        -d "token=$TOKEN" \
        http://localhost:8080)
    
    # Check if login was successful
    # Successful login redirects or shows database interface (not login form)
    if echo "$LOGIN_RESPONSE" | grep -q "noinch" && \
       ! echo "$LOGIN_RESPONSE" | grep -q "name='auth\[username\]'\|<h2>Login</h2>"; then
        echo -e "${GREEN}✓ Login successful with predefined credentials${NC}"
        
        # Additional verification: check if we can see the database
        if echo "$LOGIN_RESPONSE" | grep -q "noinch"; then
            echo -e "${GREEN}✓ Successfully accessed database 'noinch'${NC}"
            TEST_RESULT=0
        else
            echo -e "${YELLOW}⚠ Login succeeded but database access unclear${NC}"
            TEST_RESULT=0
        fi
    else
        echo -e "${RED}✗ Login failed${NC}"
        echo "Response preview (first 30 lines):"
        echo "$LOGIN_RESPONSE" | head -30
        TEST_RESULT=1
    fi
fi

# Cleanup
rm -f $COOKIE_JAR

# Show service status
echo ""
echo "Service status:"
docker-compose ps

echo ""
if [ $TEST_RESULT -eq 0 ]; then
    echo -e "${GREEN}=== Test PASSED ===${NC}"
else
    echo -e "${RED}=== Test FAILED ===${NC}"
fi

exit $TEST_RESULT
