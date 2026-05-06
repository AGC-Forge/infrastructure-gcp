#!/bin/bash

# ============================================================================
# Docker Infrastructure Deployment Script
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo ""
    echo "=========================================="
    echo "$1"
    echo "=========================================="
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Check if .env exists
if [ ! -f .env ]; then
    print_error ".env file not found!"
    echo "Creating .env from .env.example..."
    cp .env.example .env
    print_warning "Please edit .env and fill in your values, then run this script again."
    exit 1
fi

# Main script
print_header "Docker Infrastructure Deployment"

# Load environment
export $(cat .env | grep -v '#' | xargs)

print_success "Environment variables loaded"

# Check Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed!"
    exit 1
fi

print_success "Docker is installed"

# Build images
print_header "Building Docker Images"
docker-compose build

# Start services
print_header "Starting Services"
docker-compose up -d

# Wait for services to be ready
print_header "Waiting for Services to be Ready"
echo "Waiting 15 seconds for services to initialize..."
sleep 15

# Check service status
print_header "Checking Service Status"

# PostgreSQL
if docker exec infrastructure-postgres pg_isready -U ${DB_USER} &> /dev/null; then
    print_success "PostgreSQL is running"
else
    print_error "PostgreSQL is not responding"
fi

# Redis
if docker exec infrastructure-redis redis-cli -a ${REDIS_PASSWORD} ping &> /dev/null; then
    print_success "Redis is running"
else
    print_error "Redis is not responding"
fi

# MinIO
if curl -s http://localhost:9000/minio/health/live &> /dev/null; then
    print_success "MinIO is running"
else
    print_error "MinIO is not responding"
fi

# Centrifugo
if curl -s http://localhost:8000/health &> /dev/null; then
    print_success "Centrifugo is running"
else
    print_error "Centrifugo is not responding"
fi

# PgAdmin
if curl -s http://localhost:5050 &> /dev/null; then
    print_success "PgAdmin is running"
else
    print_error "PgAdmin is not responding"
fi

# Nginx
if curl -s http://localhost &> /dev/null; then
    print_success "Nginx is running"
else
    print_error "Nginx is not responding"
fi

print_header "Deployment Complete!"

echo "Services are running at:"
echo "  PostgreSQL:    localhost:${DB_PORT}"
echo "  Redis:         localhost:6379"
echo "  MinIO API:     localhost:9000"
echo "  MinIO Console: localhost:9001"
echo "  Centrifugo:    localhost:8000"
echo "  PgAdmin:       localhost:5050"
echo "  Nginx:         localhost:80"
echo ""
echo "View logs with: docker-compose logs -f"
echo "Stop services with: docker-compose down"