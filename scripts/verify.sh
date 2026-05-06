#!/bin/bash

# ============================================================================
# Docker Infrastructure Verification Script
# ============================================================================
# Comprehensive check untuk sebelum deployment

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

FAILED=0
PASSED=0

print_header() {
    echo ""
    echo -e "${BLUE}=========================================="
    echo "$1"
    echo "==========================================${NC}"
    echo ""
}

check_pass() {
    echo -e "${GREEN}✓ $1${NC}"
    ((PASSED++))
}

check_fail() {
    echo -e "${RED}✗ $1${NC}"
    ((FAILED++))
}

check_warn() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# System Requirements
print_header "Checking System Requirements"

# Check Docker
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    check_pass "Docker is installed: $DOCKER_VERSION"
else
    check_fail "Docker is not installed"
    exit 1
fi

# Check Docker Compose
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_VERSION=$(docker-compose --version)
    check_pass "Docker Compose is installed: $DOCKER_COMPOSE_VERSION"
else
    check_fail "Docker Compose is not installed"
    exit 1
fi

# Check Docker daemon
if docker ps &> /dev/null; then
    check_pass "Docker daemon is running"
else
    check_fail "Docker daemon is not running"
    exit 1
fi

# Check disk space
DISK_AVAILABLE=$(df /var 2>/dev/null | tail -1 | awk '{print $4}')
if [ "$DISK_AVAILABLE" -gt 5242880 ]; then  # 5GB
    check_pass "Disk space available: $(($DISK_AVAILABLE / 1048576))GB"
else
    check_warn "Low disk space available: $(($DISK_AVAILABLE / 1048576))GB (recommended: 5GB+)"
fi

# Check memory
if command -v free &> /dev/null; then
    MEM_AVAILABLE=$(free -m | awk 'NR==2{print $7}')
    if [ "$MEM_AVAILABLE" -gt 2048 ]; then
        check_pass "Memory available: ${MEM_AVAILABLE}MB"
    else
        check_warn "Low memory available: ${MEM_AVAILABLE}MB (recommended: 4GB+)"
    fi
fi

# Configuration Files
print_header "Checking Configuration Files"

# Check .env
if [ -f .env ]; then
    check_pass ".env file exists"
    
    # Check required environment variables
    REQUIRED_VARS=("DB_USER" "DB_PASSWORD" "DB_NAME" "REDIS_PASSWORD" "MINIO_ACCESS_KEY" "MINIO_SECRET_KEY" "CENTRIFUGO_TOKEN_SECRET" "CENTRIFUGO_API_KEY" "PGADMIN_DEFAULT_EMAIL" "PGADMIN_DEFAULT_PASSWORD")
    
    MISSING_VARS=()
    for var in "${REQUIRED_VARS[@]}"; do
        if grep -q "^${var}=" .env 2>/dev/null; then
            check_pass "Environment variable $var is set"
        else
            MISSING_VARS+=("$var")
        fi
    done
    
    if [ ${#MISSING_VARS[@]} -gt 0 ]; then
        check_fail "Missing environment variables: ${MISSING_VARS[*]}"
    fi
else
    check_fail ".env file not found"
fi

# Check docker-compose.yml
if [ -f docker-compose.yml ]; then
    check_pass "docker-compose.yml exists"
    
    # Validate YAML
    if docker-compose config > /dev/null 2>&1; then
        check_pass "docker-compose.yml is valid"
    else
        check_fail "docker-compose.yml has syntax errors"
    fi
else
    check_fail "docker-compose.yml not found"
fi

# Check supporting files
print_header "Checking Supporting Configuration Files"

SUPPORT_FILES=(
    "docker/nginx/nginx.conf"
    "docker/nginx/centrifugo/centrifugo.conf"
    "docker/nginx/minio/minio-api.conf"
    "docker/nginx/minio/minio-console.conf"
    "docker/nginx/conf.d/pgadmin.conf"
    "docker/postgres/Dockerfile.postgres"
    "docker/postgres/postgresql.conf"
    "docker/postgres/pg_hba.conf"
    "docker/postgres/healthcheck.sh"
    "docker/postgres/scripts/01-extensions.sql"
    "docker/centrifugo/config.json"
)

for file in "${SUPPORT_FILES[@]}"; do
    if [ -f "$file" ]; then
        check_pass "$file exists"
    else
        check_fail "$file not found"
    fi
done

# Port Availability
print_header "Checking Port Availability"

PORTS=(
    "80:HTTP"
    "443:HTTPS"
    "5432:PostgreSQL"
    "6379:Redis"
    "8000:Centrifugo"
    "9000:MinIO API"
    "9001:MinIO Console"
    "5050:PgAdmin"
)

for port_info in "${PORTS[@]}"; do
    PORT=${port_info%:*}
    NAME=${port_info#*:}
    
    if ! lsof -i ":$PORT" &> /dev/null 2>&1; then
        check_pass "Port $PORT ($NAME) is available"
    else
        check_warn "Port $PORT ($NAME) might be in use"
    fi
done

# Docker images
print_header "Checking Docker Images"

IMAGES=(
    "nginx:alpine"
    "postgres:16-bookworm"
    "redis:7-alpine"
    "minio/minio:latest"
    "centrifugo/centrifugo:v5"
    "dpage/pgadmin4:latest"
)

for image in "${IMAGES[@]}"; do
    if docker image inspect "$image" &> /dev/null; then
        check_pass "Docker image $image is available locally"
    else
        check_warn "Docker image $image needs to be pulled"
    fi
done

# Permissions
print_header "Checking File Permissions"

SCRIPTS=(
    "setup.sh"
    "deploy.sh"
    "monitor.sh"
    "docker/postgres/healthcheck.sh"
)

for script in "${SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            check_pass "$script is executable"
        else
            check_warn "$script is not executable (run: chmod +x $script)"
        fi
    fi
done

# Summary
print_header "Verification Summary"

echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"

if [ $FAILED -eq 0 ]; then
    echo ""
    echo -e "${GREEN}All checks passed! Ready for deployment.${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Review .env file: nano .env"
    echo "  2. Deploy services: ./deploy.sh"
    echo "  3. Monitor services: ./monitor.sh"
    echo ""
    exit 0
else
    echo ""
    echo -e "${RED}Some checks failed. Please review the issues above.${NC}"
    exit 1
fi
