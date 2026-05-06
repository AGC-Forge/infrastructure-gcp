# Docker Infrastructure Troubleshooting Guide

## Common Issues & Solutions

### 1. Docker Service Won't Start

#### Symptom

```
Error: Cannot connect to Docker daemon
```

#### Solution

```bash
# Check if Docker is running
docker ps

# If not running, start Docker service
systemctl start docker           # Linux
brew services start docker       # macOS
# Windows: Start Docker Desktop

# Check Docker logs
journalctl -u docker -n 50      # Linux
```

---

### 2. PostgreSQL Connection Error

#### Symptom

```
Error: could not translate host name "infrastructure-postgres" to address
```

#### Cause

- Docker network belum terbuat
- Container belum fully initialized

#### Solution

```bash
# Check if network exists
docker network ls | grep infrastructure-network

# If not exists, create it
docker network create infrastructure-network

# Check PostgreSQL container status
docker exec infrastructure-postgres pg_isready

# View PostgreSQL logs
docker logs infrastructure-postgres

# Try to restart
docker-compose restart postgres
```

#### Alternative: Check pg_hba.conf

```bash
# Verify authentication config
docker exec infrastructure-postgres cat /etc/postgresql/pg_hba.conf

# Ensure these lines exist:
# local   all             all                                     trust
# host    all             all             127.0.0.1/32            scram-sha-256
# host    all             all             172.16.0.0/12           scram-sha-256
```

---

### 3. Redis Authentication Failed

#### Symptom

```
Error: WRONGPASS invalid username-password pair
```

#### Cause

- REDIS_PASSWORD tidak sesuai di .env
- Redis belum fully initialized

#### Solution

```bash
# Check .env
grep REDIS_PASSWORD .env

# Verify Redis is running
docker exec infrastructure-redis redis-cli ping

# Try with password
docker exec infrastructure-redis redis-cli -a your_password ping

# If password wrong, regenerate:
1. Update .env with new password
2. Recreate Redis container:
   docker-compose down redis
   docker-compose up -d redis
```

---

### 4. MinIO Port Already in Use

#### Symptom

```
Error: bind: address already in use
```

#### Cause

- Port 9000 atau 9001 sudah digunakan service lain

#### Solution

```bash
# Linux: Check what's using the port
lsof -i :9000
lsof -i :9001

# Windows PowerShell
netstat -ano | findstr :9000
netstat -ano | findstr :9001

# Option 1: Stop the other service
# Option 2: Change MinIO ports in docker-compose.yml
# Option 3: Use different port mapping:
ports:
  - "9000:9000"  # Change left side to 9002 etc
  - "9001:9001"
```

---

### 5. Centrifugo Health Check Failing

#### Symptom

```
UNHEALTHY (health: starting)
```

#### Cause

- config.json syntax error
- Redis tidak terhubung
- Environment variables not substituted

#### Solution

```bash
# Check Centrifugo logs
docker logs infrastructure-centrifugo

# Verify config.json syntax
docker exec infrastructure-centrifugo cat /centrifugo/config.json

# Check Redis connection
docker exec infrastructure-centrifugo redis-cli -h infrastructure-redis ping

# Verify environment variables
docker exec infrastructure-centrifugo env | grep CENTRIFUGO

# Restart Centrifugo
docker-compose restart centrifugo
```

#### Fix config.json

```bash
# If config.json has issues, regenerate from template
docker exec infrastructure-centrifugo \
  centrifugo --generate-token-example
```

---

### 6. PgAdmin Can't Connect to PostgreSQL

#### Symptom

```
Unable to connect to server: could not translate host name "infrastructure-postgres" to address
```

#### Cause

- PostgreSQL not in same network
- Wrong credentials

#### Solution

```bash
# Option 1: Register server in PgAdmin UI
1. Login to PgAdmin (localhost:5050)
2. Right-click "Servers" → Register → Server
3. General tab:
   - Name: "PostgreSQL"
4. Connection tab:
   - Host name/address: infrastructure-postgres
   - Port: 5432
   - Username: ${DB_USER}
   - Password: ${DB_PASSWORD}
   - Save password: Yes
5. Click Save

# Option 2: Check networks
docker network inspect infrastructure-network

# Ensure both containers are connected
docker network connect infrastructure-network infrastructure-postgres
docker network connect infrastructure-network infrastructure-pgadmin
```

---

### 7. Nginx Cannot Reach Backend Services

#### Symptom

```
502 Bad Gateway
```

#### Cause

- Backend service not running
- Wrong hostname in nginx config
- Service not in same network

#### Solution

```bash
# Check Nginx error logs
docker logs infrastructure-nginx

# Verify backend services running
docker-compose ps

# Test from Nginx container
docker exec infrastructure-nginx curl http://infrastructure-centrifugo:8000/health
docker exec infrastructure-nginx curl http://infrastructure-minio:9000/minio/health/live
docker exec infrastructure-nginx curl http://infrastructure-pgadmin:80

# Verify config syntax
docker exec infrastructure-nginx nginx -t

# Reload Nginx
docker exec infrastructure-nginx nginx -s reload

# Check service is actually listening
docker exec infrastructure-centrifugo netstat -tlnp 2>/dev/null | grep 8000
```

---

### 8. Database Backup Fails

#### Symptom

```
pg_dump: error: connection to database "forge_db" failed
```

#### Solution

```bash
# Verify PostgreSQL running
docker exec infrastructure-postgres pg_isready

# Check user permissions
docker exec infrastructure-postgres psql -U forge -d forge_db -c "SELECT 1"

# Manual backup
docker exec infrastructure-postgres pg_dump -U forge -d forge_db > backup.sql

# Restore
cat backup.sql | docker exec -i infrastructure-postgres psql -U forge -d forge_db
```

---

### 9. Out of Disk Space

#### Symptom

```
Error: mkdir: cannot create directory: No space left on device
```

#### Solution

```bash
# Check disk usage
df -h
docker system df

# Clean up Docker
docker system prune -a
docker volume prune

# Remove old images
docker rmi $(docker images -q)

# Remove stopped containers
docker container prune

# Check logs size
du -sh /var/lib/docker/containers/*/*-json.log
```

---

### 10. Performance Issues / High CPU/Memory

#### Symptom

- Services running slow
- Container consuming lots of resources

#### Solution

```bash
# Monitor resource usage
docker stats

# Check what's consuming resources
docker top infrastructure-postgres
docker top infrastructure-redis

# PostgreSQL optimization
docker exec infrastructure-postgres psql -U forge -d forge_db -c "ANALYZE;"

# Redis memory optimization
docker exec infrastructure-redis redis-cli -a password INFO memory

# Nginx optimization - check worker processes
docker exec infrastructure-nginx cat /etc/nginx/nginx.conf | grep worker_processes
```

---

### 11. SSL Certificate Issues

#### Symptom

```
ssl_certificate missing or invalid
```

#### Solution

```bash
# Generate self-signed cert for testing
mkdir -p docker/nginx/ssl
openssl req -x509 -newkey rsa:4096 \
  -keyout docker/nginx/ssl/privkey.pem \
  -out docker/nginx/ssl/fullchain.pem \
  -days 365 -nodes

# For production, use Certbot
docker run -it --rm --name certbot \
  -v /path/to/certs:/etc/letsencrypt \
  certbot/certbot certonly \
  --standalone -d your-domain.com

# Update nginx.conf to use certificates
# Uncomment SSL section in docker-compose.yml
```

---

### 12. Network Connectivity Issues

#### Symptom

- Containers can't communicate
- "Connection refused" errors

#### Solution

```bash
# Check network status
docker network inspect infrastructure-network

# Verify DNS resolution
docker exec infrastructure-nginx nslookup infrastructure-postgres
docker exec infrastructure-nginx ping -c 1 infrastructure-redis

# Test specific ports
docker exec infrastructure-nginx nc -zv infrastructure-postgres 5432
docker exec infrastructure-nginx nc -zv infrastructure-redis 6379

# Restart networking
docker-compose down
docker network prune
docker-compose up -d
```

---

### 13. Restart Services Cleanly

#### Full Restart

```bash
# Stop all services
docker-compose down

# Remove volumes (WARNING: data loss!)
docker-compose down -v

# Rebuild and start
docker-compose build
docker-compose up -d

# Verify health
docker-compose ps
./monitor.sh
```

#### Partial Restart

```bash
# Restart single service
docker-compose restart postgres

# Rebuild single service
docker-compose up -d --build postgres

# Force recreate container
docker-compose up -d --force-recreate postgres
```

---

## Debugging Commands Reference

```bash
# View logs
docker-compose logs -f                          # All services
docker-compose logs -f postgres                 # Specific service
docker logs infrastructure-postgres --tail 100  # Last 100 lines

# Connect to container
docker exec -it infrastructure-postgres bash
docker exec -it infrastructure-redis sh

# Check processes
docker top infrastructure-postgres

# Inspect container
docker inspect infrastructure-postgres

# Copy files
docker cp infrastructure-postgres:/etc/postgresql/postgresql.conf ./
docker cp ./postgresql.conf infrastructure-postgres:/etc/postgresql/

# Performance monitoring
docker stats
docker events

# Network debugging
docker network inspect infrastructure-network
docker exec container_name netstat -tlnp
docker exec container_name ip addr

# Database operations
docker exec infrastructure-postgres psql -U forge -d forge_db -c "SELECT version();"
docker exec infrastructure-redis redis-cli PING

# Check resource limits
docker inspect infrastructure-postgres | grep -A 10 "HostConfig"
```

---

## Getting Help

1. **Check logs first**

   ```bash
   docker-compose logs -f service_name
   ```

2. **Run verification script**

   ```bash
   ./verify.sh
   ```

3. **Monitor resources**

   ```bash
   ./monitor.sh
   docker stats
   ```

4. **Review configuration**

   ```bash
   docker-compose config
   cat .env
   ```

5. **Check documentation**
   - [Docker Docs](https://docs.docker.com/)
   - [PostgreSQL Docs](https://www.postgresql.org/docs/)
   - [Redis Docs](https://redis.io/documentation)
   - [MinIO Docs](https://min.io/docs/)
   - [Centrifugo Docs](https://centrifugo.dev/docs/)

---

## Emergency Procedures

### Complete Reset

```bash
# WARNING: This will delete ALL data!
docker-compose down -v
rm -rf docker/postgres/data
rm -rf docker/redis/data
docker volume prune -f
docker-compose up -d
```

### Restore from Backup

```bash
# Restore database
./backup.sh restore-db backups/latest/db.sql

# Restore Redis
./backup.sh restore-redis backups/latest/redis_data

# Restore volumes
for file in backups/latest/volumes/*.tar.gz; do
  docker run --rm -v volume_name:/data -v $(pwd)/$file:/backup alpine tar xzf /backup -C /
done
```

---

**Last Updated:** 2026-01-20
