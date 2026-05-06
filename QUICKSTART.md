# Quick Start Guide

Panduan cepat untuk deploy Docker Infrastructure. Untuk dokumentasi lengkap, lihat [README.md](README.md).

## 🚀 5-Minute Startup

### 1. Initial Setup (Linux/Mac)

```bash
# Clone and navigate
cd d:\laragon\www\docker\infrastructure

# Generate configuration
chmod +x *.sh
./setup.sh

# Verify setup
./verify.sh
```

### 2. Start Services (Linux/Mac)

```bash
# Build and deploy
./deploy.sh
```

### 3. Start Services (Windows)

```powershell
# Run PowerShell as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\deploy.ps1 -Build -Up

# Check status
.\deploy.ps1 -Status
```

### 4. Verify Everything Works

```bash
# Check services
docker-compose ps

# View logs
docker-compose logs -f
```

---

## 🌐 Access Services

### Local Access (localhost)

| Service       | URL                   | User/Pass          |
| ------------- | --------------------- | ------------------ |
| PostgreSQL    | localhost:5432        | forge / check .env |
| Redis         | localhost:6379        | - / check .env     |
| MinIO API     | localhost:9000        | check .env         |
| MinIO Console | localhost:9001        | check .env         |
| Centrifugo    | localhost:8000        | check config       |
| PgAdmin       | http://localhost:5050 | check .env         |
| Nginx         | http://localhost      | -                  |

### Add to /etc/hosts (Linux/Mac) atau C:\Windows\System32\drivers\etc\hosts (Windows)

```
127.0.0.1   console-storage.infrastructures.help
127.0.0.1   api-storage.infrastructures.help
127.0.0.1   websocket.infrastructures.help
127.0.0.1   pgadmin.infrastructures.help
```

Then access via:

- http://console-storage.infrastructures.help:9001 (MinIO Console)
- http://pgadmin.infrastructures.help:5050 (PgAdmin)

---

## 🛠️ Common Tasks

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f postgres
docker-compose logs -f redis
docker-compose logs -f centrifugo
```

### Monitor Resources

```bash
# Real-time stats
./monitor.sh

# Or use Docker stats
docker stats
```

### Backup Data

```bash
# Full backup
./backup.sh full

# Database only
./backup.sh db

# List backups
./backup.sh list

# Restore database
./backup.sh restore-db backups/latest/postgresql_*.sql
```

### Stop Services

```bash
# Stop all
docker-compose down

# Stop specific
docker-compose stop postgres

# Stop and remove volumes (WARNING: data loss!)
docker-compose down -v
```

### Restart Services

```bash
# Restart all
docker-compose restart

# Restart specific
docker-compose restart nginx

# Rebuild and restart
docker-compose up -d --build postgres
```

### Connect to Database

```bash
# PostgreSQL interactive
docker exec -it infrastructure-postgres psql -U forge -d forge_db

# Run query
docker exec infrastructure-postgres \
  psql -U forge -d forge_db -c "SELECT * FROM table_name;"

# Redis
docker exec -it infrastructure-redis redis-cli -a password
```

### Update Environment

```bash
# Edit .env
nano .env

# Recreate containers with new env
docker-compose up -d

# Or restart specific service
docker-compose restart postgres
```

---

## 🔧 Troubleshooting Quick Fixes

### Service won't start

```bash
# Check logs
docker-compose logs service_name

# Check ports
netstat -tlnp | grep :5432
netstat -tlnp | grep :6379

# Restart Docker
sudo systemctl restart docker
docker-compose up -d
```

### Database connection error

```bash
# Test connection
docker exec infrastructure-postgres pg_isready

# Check pg_hba.conf
docker exec infrastructure-postgres cat /etc/postgresql/pg_hba.conf

# Restart PostgreSQL
docker-compose restart postgres
```

### Redis error

```bash
# Test Redis
docker exec infrastructure-redis redis-cli -a password ping

# Check memory
docker exec infrastructure-redis redis-cli -a password INFO memory

# Clear Redis
docker exec infrastructure-redis redis-cli -a password FLUSHDB
```

### Nginx error

```bash
# Check config
docker exec infrastructure-nginx nginx -t

# View error log
docker logs infrastructure-nginx

# Reload config
docker exec infrastructure-nginx nginx -s reload
```

### Port already in use

```bash
# Check what's using port
lsof -i :9000              # Linux/Mac
netstat -ano | findstr :9000  # Windows

# Kill process
kill -9 PID                # Linux/Mac
taskkill /PID PID /F       # Windows
```

---

## 📚 Documentation

| Document                                           | Purpose                        |
| -------------------------------------------------- | ------------------------------ |
| [README.md](README.md)                             | Dokumentasi lengkap            |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md)           | Panduan troubleshooting detail |
| [PRODUCTION_CHECKLIST.md](PRODUCTION_CHECKLIST.md) | Checklist sebelum production   |
| [DNS_CONFIGURATION.md](DNS_CONFIGURATION.md)       | Setup DNS & domain             |

---

## 📞 Need Help?

1. **Check logs first**

   ```bash
   docker-compose logs -f
   ```

2. **Read troubleshooting guide**
   - See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

3. **Verify installation**

   ```bash
   ./verify.sh
   ```

4. **Monitor services**
   ```bash
   ./monitor.sh
   ```

---

## 🔗 Useful Commands

```bash
# Compose commands
docker-compose build              # Build images
docker-compose up -d              # Start services
docker-compose down               # Stop services
docker-compose ps                 # List running containers
docker-compose logs -f            # View logs
docker-compose exec SERVICE bash  # Access container

# Service management
docker ps                         # List containers
docker images                     # List images
docker stats                      # View resource usage
docker system df                  # Disk usage
docker system prune               # Clean up

# Network
docker network ls                 # List networks
docker network inspect NAME       # Inspect network
docker exec CONTAINER ping OTHER  # Test connectivity

# Volumes
docker volume ls                  # List volumes
docker volume inspect NAME        # Inspect volume
docker volume rm NAME             # Remove volume
```

---

## 📋 Typical Workflow

### Development

```bash
# 1. Setup
./setup.sh
./verify.sh

# 2. Start services
./deploy.sh

# 3. Test application
# ... make changes ...

# 4. View logs
docker-compose logs -f

# 5. Stop when done
docker-compose down
```

### Backup & Maintenance

```bash
# 1. Daily backup
./backup.sh full

# 2. Monitor health
./monitor.sh

# 3. Check resource usage
docker stats

# 4. Update if needed
docker-compose pull
docker-compose up -d
```

### Emergency

```bash
# 1. Check status
docker-compose ps
./monitor.sh

# 2. View logs
docker-compose logs -f

# 3. Restart affected service
docker-compose restart SERVICE

# 4. Full restart if needed
docker-compose restart

# 5. Check recovery
./monitor.sh
```

---

**For detailed documentation, see [README.md](README.md)**

**Last Updated:** 2026-01-20
