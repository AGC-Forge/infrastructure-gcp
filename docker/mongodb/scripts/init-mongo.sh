#!/bin/bash

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}MongoDB Initialization Helper${NC}"
echo -e "${GREEN}========================================${NC}"

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '#' | awk '/=/ {print $1}')
    echo -e "${GREEN}✓ Environment variables loaded from .env${NC}"
else
    echo -e "${YELLOW}⚠ .env file not found, using defaults${NC}"
fi

# Tampilkan konfigurasi yang akan digunakan
echo -e "\n${YELLOW}Configuration:${NC}"
echo "Root User: forge"
echo "App Database: forge_db"
echo "App User: forge"
echo "App Password: Resti#2305"

# Confirm
echo -e "\n${YELLOW}Proceed with initialization? (y/n)${NC}"
read -r confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo -e "${RED}Initialization cancelled${NC}"
    exit 1
fi

# Jalankan inisialisasi
echo -e "\n${GREEN}Starting MongoDB initialization...${NC}"

# Copy template ke container dan execute
docker cp docker/mongodb/scripts/init.js infrastructure-mongodb:/tmp/init.js
docker exec infrastructure-mongodb mongosh --eval "load('/tmp/init.js')"

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}✓ MongoDB initialization completed successfully!${NC}"
else
    echo -e "\n${RED}✗ MongoDB initialization failed!${NC}"
    exit 1
fi