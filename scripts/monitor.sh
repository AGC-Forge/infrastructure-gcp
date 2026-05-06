#!/bin/bash

# ============================================================================
# Docker Infrastructure Monitoring Script
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${BLUE}=========================================="
    echo "$1"
    echo "==========================================${NC}"
    echo ""
}

print_status() {
    local service=$1
    local status=$2
    local color=$3
    echo -e "${color}${service}: ${status}${NC}"
}

# Load .env
if [ -f .env ]; then
    export $(cat .env | grep -v '#' | xargs)
fi

print_header "Docker Infrastructure Monitoring"

# Docker stats
print_header "Container Resource Usage"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" || true

# Service status
print_header "Service Health Status"

# PostgreSQL
if docker exec infrastructure-postgres pg_isready -U ${DB_USER:-forge} &> /dev/null; then
    print_status "PostgreSQL" "✓ Running" "$GREEN"
    # Show connection count
    CONN_COUNT=$(docker exec infrastructure-postgres psql -U ${DB_USER:-forge} -t -c "SELECT count(*) FROM pg_stat_activity;" 2>/dev/null || echo "N/A")
    echo "  Active connections: $CONN_COUNT"
else
    print_status "PostgreSQL" "✗ Not responding" "$RED"
fi

# Redis
if docker exec infrastructure-redis redis-cli -a ${REDIS_PASSWORD} ping &> /dev/null 2>&1; then
    print_status "Redis" "✓ Running" "$GREEN"
    # Show memory usage
    MEM_INFO=$(docker exec infrastructure-redis redis-cli -a ${REDIS_PASSWORD} INFO memory 2>/dev/null | grep used_memory_human | cut -d: -f2)
    echo "  Memory usage: $MEM_INFO"
else
    print_status "Redis" "✗ Not responding" "$RED"
fi

# MinIO
if curl -s http://localhost:9000/minio/health/live &> /dev/null; then
    print_status "MinIO" "✓ Running" "$GREEN"
else
    print_status "MinIO" "✗ Not responding" "$RED"
fi

# Centrifugo
if curl -s http://localhost:8000/health &> /dev/null; then
    print_status "Centrifugo" "✓ Running" "$GREEN"
else
    print_status "Centrifugo" "✗ Not responding" "$RED"
fi

# PgAdmin
if curl -s http://localhost:5050 &> /dev/null; then
    print_status "PgAdmin" "✓ Running" "$GREEN"
else
    print_status "PgAdmin" "✗ Not responding" "$RED"
fi

# Nginx
if curl -s http://localhost &> /dev/null; then
    print_status "Nginx" "✓ Running" "$GREEN"
else
    print_status "Nginx" "✗ Not responding" "$RED"
fi

# Disk usage
print_header "Disk Usage"
docker system df

# Database size
print_header "Database Information"
if docker exec infrastructure-postgres pg_isready -U ${DB_USER:-forge} &> /dev/null 2>&1; then
    echo "Database: ${DB_NAME:-forge_db}"
    docker exec infrastructure-postgres psql -U ${DB_USER:-forge} -d ${DB_NAME:-forge_db} -c "\l" 2>/dev/null | head -5 || true
else
    echo "PostgreSQL not available"
fi

print_header "End of Report"
