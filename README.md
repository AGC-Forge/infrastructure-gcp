# Docker Infrastructure Setup

Infrastruktur Docker yang lengkap dengan MinIO, Redis, Centrifugo, PostgreSQL, PgAdmin, dan Nginx Reverse Proxy.

## 📋 Daftar Services

### Production Services

- **PostgreSQL** - Database relasional untuk aplikasi
- **Redis** - In-memory cache dan message broker
- **MinIO** - Object storage (S3-compatible)
- **Centrifugo** - Real-time messaging & WebSocket server
- **PgAdmin** - PostgreSQL management UI
- **Nginx** - Reverse proxy dengan SSL support

## 🗂️ Struktur Direktori

```
docker/
├── centrifugo/
│   ├── config.json          # Centrifugo configuration
│   └── entrypoint.sh        # Entrypoint script with env substitution
├── nginx/
│   ├── nginx.conf           # Main Nginx configuration
│   ├── conf.d/
│   │   └── pgadmin.conf     # PgAdmin reverse proxy config
│   ├── centrifugo/
│   │   └── centrifugo.conf  # Centrifugo reverse proxy config
│   ├── minio/
│   │   ├── minio-api.conf   # MinIO API reverse proxy config
│   │   └── minio-console.conf # MinIO Console reverse proxy config
│   └── Dockerfile           # Nginx custom image
└── postgres/
    ├── Dockerfile.postgres  # PostgreSQL custom image
    ├── postgresql.conf      # PostgreSQL configuration
    ├── pg_hba.conf          # PostgreSQL authentication config
    ├── healthcheck.sh       # Health check script
    └── scripts/
        └── 01-extensions.sql # Database extensions initialization

docker-compose.yml          # Main Docker Compose configuration
.env.example               # Environment variables template
```

## 🚀 Quickstart

### 1. Persiapan

```bash
# Clone repository
cd d:\laragon\www\docker\infrastructure

# Copy environment variables
cp .env.example .env

# Edit .env dengan nilai-nilai Anda
# Ganti placeholder dengan nilai real
nano .env
```

### 2. Konfigurasi Environment Variables

Edit file `.env` dan atur nilai-nilai berikut:

```bash
# Database
DB_USER=forge
DB_PASSWORD=your_strong_password
DB_NAME=forge_db

# Redis
REDIS_PASSWORD=your_redis_password

# MinIO
MINIO_ACCESS_KEY=your_access_key
MINIO_SECRET_KEY=your_secret_key

# Centrifugo
CENTRIFUGO_TOKEN_SECRET=your_token_secret
CENTRIFUGO_API_KEY=your_api_key
CENTRIFUGO_ADMIN_PASSWORD=your_admin_password
CENTRIFUGO_ADMIN_SECRET=your_admin_secret

# PgAdmin
PGADMIN_DEFAULT_EMAIL=admin@example.com
PGADMIN_DEFAULT_PASSWORD=your_pgadmin_password
```

### 3. Build dan Start Services

```bash
# Build images
docker-compose build

# Start semua services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

### 4. Verifikasi Services

```bash
# PostgreSQL
docker exec infrastructure-postgres pg_isready -U forge

# Redis
docker exec infrastructure-redis redis-cli -a $REDIS_PASSWORD ping

# MinIO
curl http://localhost:9000/minio/health/live

# Centrifugo
curl http://localhost:8000/health

# PgAdmin
curl http://localhost:5050

# Nginx
curl http://localhost
```

## 📡 Akses Services

### Local Access (Development)

| Service       | URL            | Credentials              |
| ------------- | -------------- | ------------------------ |
| PostgreSQL    | localhost:5432 | User/Password dari .env  |
| Redis         | localhost:6379 | Password dari .env       |
| MinIO API     | localhost:9000 | User/Password dari .env  |
| MinIO Console | localhost:9001 | User/Password dari .env  |
| Centrifugo    | localhost:8000 | Lihat config.json        |
| PgAdmin       | localhost:5050 | Email/Password dari .env |

### Public Access (via Nginx Reverse Proxy)

Ubah domain berikut sesuai domain Anda di file konfigurasi Nginx:

| Service       | Domain (Example)                     |
| ------------- | ------------------------------------ |
| MinIO Console | console-storage.infrastructures.help |
| MinIO API     | api-storage.infrastructures.help     |
| Centrifugo    | websocket.infrastructures.help       |
| PgAdmin       | pgadmin.infrastructures.help         |

## 🔧 Konfigurasi Detail

### PostgreSQL

**File:** `docker/postgres/postgresql.conf`

Konfigurasi yang sudah dioptimalkan untuk production:

- Memory: 512MB shared_buffers, 2GB effective_cache_size
- WAL: Replica-ready dengan max_wal_size = 2GB
- Logging: Query slower than 5 seconds, connection tracking
- Security: SCRAM-SHA-256 password encryption

**Customization:**

```bash
# Untuk mengubah port
DB_PORT=5433

# Untuk mengubah memory settings, edit postgresql.conf
shared_buffers = 512MB        # Adjust based on your RAM
effective_cache_size = 2GB    # Adjust based on your RAM
```

### Redis

**Configuration:**

- Memory limit: 512MB dengan LRU eviction policy
- Persistence: AOF (Append Only File) enabled
- Health check: Setiap 10 detik
- Resource limits: 1 CPU, 1GB RAM max

**Access:**

```bash
# Connect ke Redis
docker exec -it infrastructure-redis redis-cli -a $REDIS_PASSWORD

# Test connection
ping
```

### Centrifugo

**File:** `docker/centrifugo/config.json`

Fitur yang diaktifkan:

- Redis engine untuk scalability
- Admin panel (insecure mode disabled)
- Prometheus metrics export
- Namespaces: chat, notifications, presence, typing
- gRPC API untuk integration

**Environment Variables:**

- `CENTRIFUGO_TOKEN_SECRET` - Token signing key
- `CENTRIFUGO_API_KEY` - API access key
- `CENTRIFUGO_ADMIN_PASSWORD` - Admin panel password
- `REDIS_PASSWORD` - Redis authentication

### MinIO

**Configuration:**

- Ports: 9000 (API), 9001 (Console)
- Browser redirect: https://console-storage.infrastructures.help
- API endpoint: https://api-storage.infrastructures.help

**Access:**

```bash
# MinIO Console
http://localhost:9001
Username: ${MINIO_ACCESS_KEY}
Password: ${MINIO_SECRET_KEY}

# Create bucket
docker exec infrastructure-minio \
  mc mb minio/mybucket
```

### Nginx

**File:** `docker/nginx/nginx.conf`

Fitur:

- Worker processes: auto
- Max body size: 100MB
- Gzip compression: enabled
- Security headers: SAMEORIGIN, X-Content-Type-Options, X-XSS-Protection
- Rate limiting zones untuk API dan Auth

**Reverse Proxy Backends:**

- MinIO Console (port 9001)
- MinIO API (port 9000)
- Centrifugo (port 8000)
- PgAdmin (port 80)

**Custom Config:** Tambahkan file `.conf` baru di `docker/nginx/conf.d/`

### PgAdmin

**Features:**

- Master password required untuk security
- Server mode: False (single user mode)
- Automatic PostgreSQL connection setup

**Setup:**

```bash
# Login ke PgAdmin
http://localhost:5050
Email: ${PGADMIN_DEFAULT_EMAIL}
Password: ${PGADMIN_DEFAULT_PASSWORD}

# Auto-add PostgreSQL server
Server Name: PostgreSQL
Host name/address: infrastructure-postgres
Username: ${DB_USER}
Password: ${DB_PASSWORD}
```

## 🔒 Security Best Practices

### 1. Password Security

```bash
# Generate strong password
openssl rand -base64 32

# Update di .env
REDIS_PASSWORD=generated_password_here
DB_PASSWORD=generated_password_here
MINIO_SECRET_KEY=generated_password_here
```

### 2. SSL/TLS Setup

```bash
# Uncomment volume di docker-compose.yml
volumes:
  - ./docker/nginx/ssl:/etc/nginx/ssl:ro

# Generate self-signed cert untuk development
mkdir -p docker/nginx/ssl
openssl req -x509 -newkey rsa:4096 -keyout docker/nginx/ssl/privkey.pem \
  -out docker/nginx/ssl/fullchain.pem -days 365 -nodes

# Untuk production, gunakan Let's Encrypt Certbot
```

### 3. Network Isolation

Services hanya berkomunikasi via Docker network `infrastructure-network`:

- PostgreSQL hanya accessible dari container atau port 5432
- Redis hanya accessible dari container atau port 6379
- MinIO API hanya via nginx proxy

### 4. Database Backup

```bash
# Backup PostgreSQL
docker exec infrastructure-postgres \
  pg_dump -U forge forge_db > backup.sql

# Restore PostgreSQL
docker exec -i infrastructure-postgres \
  psql -U forge forge_db < backup.sql

# Backup Redis
docker exec infrastructure-redis \
  redis-cli -a $REDIS_PASSWORD BGSAVE

# Backup MinIO
docker exec infrastructure-minio \
  mc mirror minio/mybucket ./backup/
```

## 📊 Monitoring & Logs

### View Logs

```bash
# Semua services
docker-compose logs -f

# Service specific
docker-compose logs -f postgres
docker-compose logs -f redis
docker-compose logs -f centrifugo
docker-compose logs -f nginx

# Last 100 lines
docker-compose logs --tail=100 postgres
```

### Performance Monitoring

```bash
# PostgreSQL connections
docker exec infrastructure-postgres \
  psql -U forge -d forge_db -c "SELECT * FROM pg_stat_activity;"

# Redis memory usage
docker exec infrastructure-redis \
  redis-cli -a $REDIS_PASSWORD INFO memory

# Centrifugo metrics
curl http://localhost:8000/metrics

# Container stats
docker stats
```

## 🚨 Troubleshooting

### PostgreSQL tidak connect

```bash
# Check logs
docker-compose logs postgres

# Test connection
docker exec infrastructure-postgres \
  pg_isready -U forge -h infrastructure-postgres

# Check pg_hba.conf
docker exec infrastructure-postgres \
  cat /etc/postgresql/pg_hba.conf
```

### Redis connection failed

```bash
# Check Redis running
docker exec infrastructure-redis \
  redis-cli -a $REDIS_PASSWORD ping

# Check logs
docker-compose logs redis
```

### Nginx proxy error

```bash
# Check Nginx config
docker exec infrastructure-nginx \
  nginx -t

# Check backend connectivity
docker exec infrastructure-nginx \
  curl http://infrastructure-centrifugo:8000

# Reload Nginx
docker exec infrastructure-nginx \
  nginx -s reload
```

### Services won't start

```bash
# Check docker-compose syntax
docker-compose config

# Check port conflicts
netstat -ano | findstr :9000
netstat -ano | findstr :5432

# Rebuild containers
docker-compose down
docker-compose up --build

# Check disk space
docker system df
```

## 🧹 Maintenance

### Update Services

```bash
# Pull latest images
docker-compose pull

# Rebuild dan restart
docker-compose up -d --build

# Remove unused resources
docker system prune -a
```

### Health Checks

Services sudah memiliki built-in health checks. View status:

```bash
docker-compose ps

# Manual health check
docker exec infrastructure-postgres /usr/local/bin/healthcheck.sh
docker exec infrastructure-redis redis-cli -a $REDIS_PASSWORD ping
```

### Database Maintenance

```bash
# PostgreSQL vacuum & analyze
docker exec infrastructure-postgres \
  psql -U forge -d forge_db -c "VACUUM ANALYZE;"

# Redis memory optimization
docker exec infrastructure-redis \
  redis-cli -a $REDIS_PASSWORD INFO stats
```

## 📝 Environment Variables Reference

| Variable                  | Default           | Description                 |
| ------------------------- | ----------------- | --------------------------- |
| COMPOSE_PROJECT_NAME      | infrastructure    | Docker compose project name |
| NGINX_HTTP_PORT           | 80                | HTTP port                   |
| NGINX_HTTPS_PORT          | 443               | HTTPS port                  |
| DB_USER                   | forge             | PostgreSQL username         |
| DB_PASSWORD               | -                 | PostgreSQL password         |
| DB_NAME                   | forge_db          | PostgreSQL database name    |
| DB_PORT                   | 5432              | PostgreSQL port             |
| REDIS_PASSWORD            | -                 | Redis password              |
| MINIO_ACCESS_KEY          | -                 | MinIO access key            |
| MINIO_SECRET_KEY          | -                 | MinIO secret key            |
| CENTRIFUGO_TOKEN_SECRET   | -                 | Centrifugo token secret     |
| CENTRIFUGO_API_KEY        | -                 | Centrifugo API key          |
| CENTRIFUGO_ADMIN_PASSWORD | -                 | Centrifugo admin password   |
| PGADMIN_DEFAULT_EMAIL     | admin@example.com | PgAdmin login email         |
| PGADMIN_DEFAULT_PASSWORD  | -                 | PgAdmin login password      |

## 🔗 Links & Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Redis Documentation](https://redis.io/documentation)
- [MinIO Documentation](https://min.io/docs/)
- [Centrifugo Documentation](https://centrifugo.dev/docs/server/)
- [PgAdmin Documentation](https://www.pgadmin.org/docs/)
- [Nginx Documentation](https://nginx.org/en/docs/)

## 📄 License

This infrastructure setup is provided as-is for development and production use.

## 👤 Support

Untuk issue atau pertanyaan, silakan hubungi tim infrastructure atau buat issue di repository.

---

**Last Updated:** 2026-01-20
**Version:** 1.0.0
