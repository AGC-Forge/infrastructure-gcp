#!/bin/bash

# ============================================================================
# Docker Infrastructure Setup Script
# ============================================================================
# Generate secure passwords dan setup awal

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

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Generate random password
generate_password() {
    local length=${1:-32}
    openssl rand -base64 $length | tr -d '\n'
}

# Generate random alphanumeric
generate_random() {
    local length=${1:-32}
    openssl rand -base64 $length | tr -d '=+/\n' | cut -c1-$length
}

print_header "Docker Infrastructure Setup"

# Check if .env exists
if [ -f .env ]; then
    print_warning ".env file already exists!"
    read -p "Do you want to regenerate passwords? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# Start generating
print_header "Generating Secrets and Configuration"

# Generate passwords
DB_PASS=$(generate_password)
REDIS_PASS=$(generate_password)
MINIO_ACCESS=$(generate_random 20)
MINIO_SECRET=$(generate_password 32)
CENTRIFUGO_TOKEN=$(generate_password 64)
CENTRIFUGO_API=$(generate_password 64)
CENTRIFUGO_ADMIN_PASS=$(generate_password)
CENTRIFUGO_ADMIN_SECRET=$(generate_password 64)
PGADMIN_PASS=$(generate_password)

print_success "Passwords generated"

# Create .env file
cat > .env << EOF
# ============================================================================
# AUTO-GENERATED CONFIGURATION
# Generated: $(date)
# ============================================================================

# General
COMPOSE_PROJECT_NAME=infrastructure

# Nginx
NGINX_HTTP_PORT=8080
NGINX_HTTPS_PORT=443

# PostgreSQL
DB_USER=forge
DB_PASSWORD=$DB_PASS
DB_NAME=forge_db
DB_PORT=5432

POSTGRES_USER=forge
POSTGRES_PASSWORD=$DB_PASS
POSTGRES_DB=forge_db

# Redis
REDIS_PASSWORD=$REDIS_PASS

# MinIO
MINIO_ACCESS_KEY=$MINIO_ACCESS
MINIO_SECRET_KEY=$MINIO_SECRET
MINIO_BROWSER_REDIRECT_URL=https://console-storage.infrastructures.help
MINIO_SERVER_URL=https://api-storage.infrastructures.help
MINIO_BUCKET=agc-forge

# Centrifugo
CENTRIFUGO_TOKEN_SECRET=$CENTRIFUGO_TOKEN
CENTRIFUGO_API_KEY=$CENTRIFUGO_API
CENTRIFUGO_ADMIN_PASSWORD=$CENTRIFUGO_ADMIN_PASS
CENTRIFUGO_ADMIN_SECRET=$CENTRIFUGO_ADMIN_SECRET

# PgAdmin
PGADMIN_DEFAULT_EMAIL=admin@example.com
PGADMIN_DEFAULT_PASSWORD=$PGADMIN_PASS
EOF

print_success ".env file created with generated secrets"

print_header "Generated Configuration"

cat << EOF
${GREEN}PostgreSQL:${NC}
  User: forge
  Password: $DB_PASS
  Database: forge_db
  Port: 5432

${GREEN}Redis:${NC}
  Password: $REDIS_PASS
  Port: 6379

${GREEN}MinIO:${NC}
  Access Key: $MINIO_ACCESS
  Secret Key: $MINIO_SECRET
  API Port: 9000
  Console Port: 9001

${GREEN}Centrifugo:${NC}
  Token Secret: $CENTRIFUGO_TOKEN
  API Key: $CENTRIFUGO_API
  Admin Password: $CENTRIFUGO_ADMIN_PASS
  Admin Secret: $CENTRIFUGO_ADMIN_SECRET
  Port: 8000

${GREEN}PgAdmin:${NC}
  Email: admin@example.com
  Password: $PGADMIN_PASS
  Port: 5050

${GREEN}Nginx:${NC}
  HTTP Port: 8080
  HTTPS Port: 8443
EOF

print_warning "Please save these credentials in a secure location!"
print_warning "The .env file will not be committed to git for security."

print_header "Next Steps"

echo "1. Review the generated .env file:"
echo "   nano .env"
echo ""
echo "2. Update domain names in Nginx config:"
echo "   - docker/nginx/centrifugo/centrifugo.conf"
echo "   - docker/nginx/minio/minio-*.conf"
echo "   - docker/nginx/conf.d/pgadmin.conf"
echo ""
echo "3. Build and start services:"
echo "   ./deploy.sh"
echo ""
echo "4. Monitor services:"
echo "   ./monitor.sh"
echo ""

print_success "Setup complete!"
