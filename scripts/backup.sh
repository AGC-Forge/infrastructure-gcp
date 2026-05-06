#!/bin/bash

# ============================================================================
# Docker Infrastructure Backup & Restore Script
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

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Load .env
if [ -f .env ]; then
    export $(cat .env | grep -v '#' | xargs)
fi

# Backup directory
BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Functions
backup_postgresql() {
    print_header "Backing up PostgreSQL Database"
    
    local db_user=${DB_USER:-forge}
    local db_name=${DB_NAME:-forge_db}
    local backup_file="$BACKUP_DIR/postgresql_${db_name}_$(date +%Y%m%d_%H%M%S).sql"
    
    docker exec infrastructure-postgres pg_dump -U "$db_user" -d "$db_name" > "$backup_file"
    
    if [ -f "$backup_file" ]; then
        local size=$(du -h "$backup_file" | cut -f1)
        print_success "PostgreSQL backup created: $backup_file ($size)"
    else
        print_error "Failed to create PostgreSQL backup"
        return 1
    fi
}

backup_redis() {
    print_header "Backing up Redis Data"
    
    docker exec infrastructure-redis redis-cli -a "${REDIS_PASSWORD}" BGSAVE > /dev/null
    
    # Wait for backup to complete
    sleep 2
    
    docker cp infrastructure-redis:/data "$BACKUP_DIR/redis_data"
    
    print_success "Redis backup created: $BACKUP_DIR/redis_data"
}

backup_minio() {
    print_header "Backing up MinIO Data"
    
    # List buckets
    BUCKETS=$(docker exec infrastructure-minio mc ls minio 2>/dev/null | awk '{print $NF}' || true)
    
    if [ -z "$BUCKETS" ]; then
        print_success "No MinIO buckets to backup"
        return 0
    fi
    
    mkdir -p "$BACKUP_DIR/minio"
    
    for bucket in $BUCKETS; do
        docker exec infrastructure-minio mc mirror "minio/$bucket" "/backup/$bucket" > /dev/null 2>&1 || true
    done
    
    docker cp infrastructure-minio:/backup "$BACKUP_DIR/minio" 2>/dev/null || true
    
    print_success "MinIO backup created: $BACKUP_DIR/minio"
}

backup_pgadmin() {
    print_header "Backing up PgAdmin Configuration"
    
    docker cp infrastructure-pgadmin:/var/lib/pgadmin "$BACKUP_DIR/pgadmin_data"
    
    print_success "PgAdmin backup created: $BACKUP_DIR/pgadmin_data"
}

backup_volumes() {
    print_header "Backing up Docker Volumes"
    
    # Backup volume data
    for volume in postgres_data redis_data minio_data pgadmin_data; do
        if docker volume inspect "$volume" > /dev/null 2>&1; then
            mkdir -p "$BACKUP_DIR/volumes"
            docker run --rm -v "$volume:/data" -v "$BACKUP_DIR/volumes:/backup" alpine tar czf "/backup/${volume}.tar.gz" -C / data > /dev/null 2>&1 || true
            print_success "Volume $volume backed up"
        fi
    done
}

restore_postgresql() {
    local backup_file=$1
    
    print_header "Restoring PostgreSQL Database"
    
    if [ ! -f "$backup_file" ]; then
        print_error "Backup file not found: $backup_file"
        return 1
    fi
    
    docker exec -i infrastructure-postgres psql -U ${DB_USER:-forge} -d ${DB_NAME:-forge_db} < "$backup_file"
    
    print_success "PostgreSQL restored from: $backup_file"
}

restore_redis() {
    local backup_dir=$1
    
    print_header "Restoring Redis Data"
    
    if [ ! -d "$backup_dir" ]; then
        print_error "Backup directory not found: $backup_dir"
        return 1
    fi
    
    docker cp "$backup_dir" infrastructure-redis:/data_restored
    docker exec infrastructure-redis redis-cli -a "${REDIS_PASSWORD}" FLUSHDB > /dev/null
    docker exec infrastructure-redis bash -c "cat /data_restored/dump.rdb > /data/dump.rdb" || true
    
    print_success "Redis restored from: $backup_dir"
}

backup_config() {
    print_header "Backing up Configuration Files"
    
    mkdir -p "$BACKUP_DIR/config"
    
    cp .env "$BACKUP_DIR/config/.env" 2>/dev/null || true
    cp docker-compose.yml "$BACKUP_DIR/config/docker-compose.yml"
    cp -r docker "$BACKUP_DIR/config/docker"
    
    print_success "Configuration backed up: $BACKUP_DIR/config"
}

# Main script
case "${1:-help}" in
    full)
        print_header "Full System Backup"
        backup_postgresql
        backup_redis
        backup_minio
        backup_pgadmin
        backup_volumes
        backup_config
        print_header "Backup Complete"
        echo "Backup location: $BACKUP_DIR"
        ;;
    
    db)
        backup_postgresql
        ;;
    
    redis)
        backup_redis
        ;;
    
    minio)
        backup_minio
        ;;
    
    pgadmin)
        backup_pgadmin
        ;;
    
    config)
        backup_config
        ;;
    
    restore-db)
        if [ -z "$2" ]; then
            print_error "Usage: $0 restore-db <backup-file>"
            exit 1
        fi
        restore_postgresql "$2"
        ;;
    
    restore-redis)
        if [ -z "$2" ]; then
            print_error "Usage: $0 restore-redis <backup-dir>"
            exit 1
        fi
        restore_redis "$2"
        ;;
    
    list)
        print_header "Available Backups"
        ls -lh backups/ 2>/dev/null || echo "No backups found"
        ;;
    
    *)
        echo "Docker Infrastructure Backup & Restore Tool"
        echo ""
        echo "Usage: $0 <command> [options]"
        echo ""
        echo "Commands:"
        echo "  full              - Backup all data (PostgreSQL, Redis, MinIO, PgAdmin, volumes)"
        echo "  db                - Backup PostgreSQL database only"
        echo "  redis             - Backup Redis data only"
        echo "  minio             - Backup MinIO buckets only"
        echo "  pgadmin           - Backup PgAdmin configuration only"
        echo "  config            - Backup configuration files only"
        echo "  restore-db <file> - Restore PostgreSQL from backup file"
        echo "  restore-redis <dir> - Restore Redis from backup directory"
        echo "  list              - List available backups"
        echo ""
        echo "Examples:"
        echo "  $0 full                                   # Full backup"
        echo "  $0 db                                     # Backup database only"
        echo "  $0 restore-db backups/2026.../db.sql     # Restore database"
        echo "  $0 list                                   # List all backups"
        echo ""
        ;;
esac
