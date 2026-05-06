# Production Deployment Checklist

Checklist lengkap sebelum deploy ke production server Ubuntu.

## 📋 Pre-Deployment Phase

### Infrastructure Preparation

- [ ] Server Ubuntu tersedia dan accessible via SSH
- [ ] Ubuntu OS updated: `sudo apt update && apt upgrade -y`
- [ ] Docker installed: `curl -fsSL https://get.docker.com | sh`
- [ ] docker-compose installed: `sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose`
- [ ] Disk space: Minimal 50GB untuk production data
- [ ] Memory: Minimal 8GB RAM
- [ ] CPU: Minimal 4 cores recommended
- [ ] Network: Static IP address configured
- [ ] Firewall: Rules configured untuk ports 80, 443, 22

### Repository & Code

- [ ] Project cloned to `/opt/docker/infrastructure` atau equivalent
- [ ] Git history preserved
- [ ] All configuration files present
- [ ] Scripts executable: `chmod +x *.sh`

### Security Setup

- [ ] Generate strong passwords: `./setup.sh`
- [ ] .env file created dengan secure values
- [ ] .env file permissions restricted: `chmod 600 .env`
- [ ] .env file not committed to git
- [ ] SSH keys configured
- [ ] Firewall rules applied
- [ ] SSL certificates ready (atau Let's Encrypt domain configured)

---

## 🔐 Security Checklist

### Network Security

- [ ] Docker network isolated
- [ ] Only necessary ports exposed
- [ ] Non-routable internal network configured
- [ ] Firewall blocking unwanted access:
  ```bash
  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw allow 22/tcp     # SSH
  sudo ufw allow 80/tcp     # HTTP
  sudo ufw allow 443/tcp    # HTTPS
  sudo ufw enable
  ```

### Credentials & Secrets

- [ ] All passwords randomly generated (min 32 chars)
- [ ] Secrets not in version control
- [ ] .env file encrypted or stored securely
- [ ] Database superuser password changed
- [ ] Redis password enabled
- [ ] MinIO credentials secured
- [ ] API keys rotated if reused

### SSL/TLS

- [ ] SSL certificates obtained (Let's Encrypt recommended)
- [ ] Certificate paths correct in nginx config
- [ ] Auto-renewal configured (Certbot)
- [ ] HTTP → HTTPS redirect enabled
- [ ] Security headers configured

### Access Control

- [ ] SSH key-based auth only (no password SSH)
- [ ] PgAdmin master password set
- [ ] PostgreSQL pg_hba.conf restricted
- [ ] MinIO console password protected
- [ ] Centrifugo admin secured

---

## 📊 Database Configuration

### PostgreSQL

- [ ] Database user created: `forge`
- [ ] Strong password set
- [ ] Max connections appropriate: `max_connections = 200`
- [ ] Shared buffers sized: `shared_buffers = 512MB` (25% RAM)
- [ ] WAL level: `wal_level = replica`
- [ ] Backup schedule configured:
  ```bash
  # Add to crontab
  0 2 * * * /opt/docker/infrastructure/backup.sh full
  ```
- [ ] Point-in-time recovery configured
- [ ] Extensions installed: pg_cron, pg_stat_statements, etc

### Redis

- [ ] Password protection enabled
- [ ] Memory limit set: `maxmemory 512mb`
- [ ] Eviction policy: `maxmemory-policy allkeys-lru`
- [ ] Persistence enabled: `appendonly yes`
- [ ] AOF rewrite frequency configured
- [ ] Monitoring setup

### Backups

- [ ] Backup directory exists: `/backups` with adequate space
- [ ] Automated backup script scheduled
- [ ] Backup retention policy: 30 days min
- [ ] Restore procedure tested
- [ ] Offsite backup copy made monthly

---

## 🎯 Application Configuration

### MinIO

- [ ] Access keys rotated from defaults
- [ ] Buckets created for application
- [ ] Bucket policies configured
- [ ] Lifecycle policies for old objects
- [ ] CORS configured if needed
- [ ] Monitoring/metrics enabled

### Centrifugo

- [ ] Secrets regenerated
- [ ] Redis integration configured
- [ ] Namespaces configured per requirements
- [ ] Admin panel access restricted
- [ ] Metrics endpoint secured
- [ ] Connection limits set appropriately

### PostgreSQL & PgAdmin

- [ ] Initial databases created
- [ ] PgAdmin server registered
- [ ] Users created with limited permissions
- [ ] Tables and schemas initialized
- [ ] Indexes created for performance

### Nginx

- [ ] Upstream servers configured
- [ ] SSL certificates installed
- [ ] Security headers enabled
- [ ] Rate limiting configured
- [ ] GZIP compression enabled
- [ ] Log rotation configured
- [ ] Access logs enabled
- [ ] Error pages customized (optional)

---

## 🚀 Deployment Phase

### Pre-Deployment Verification

- [ ] Run verification script: `./verify.sh`
- [ ] All checks passing
- [ ] Disk space confirmed
- [ ] Memory available
- [ ] Network connectivity tested

### Initial Deployment

```bash
# 1. Generate secrets
./setup.sh

# 2. Verify configuration
./verify.sh

# 3. Build images
docker-compose build

# 4. Start services
docker-compose up -d

# 5. Monitor
./monitor.sh
```

### Post-Deployment Verification

- [ ] All containers running: `docker-compose ps`
- [ ] Health checks passing
- [ ] Services responding: `./monitor.sh`
- [ ] Database connected
- [ ] Redis cache working
- [ ] MinIO accessible
- [ ] Centrifugo responding
- [ ] PgAdmin accessible
- [ ] Nginx proxy working

### Monitoring Setup

- [ ] Docker stats monitored
- [ ] Logs aggregated/rotated
- [ ] Alerts configured:
  - [ ] Disk space low
  - [ ] Memory usage high
  - [ ] Services unhealthy
  - [ ] Database connections at limit
  - [ ] Redis memory at limit

---

## 📈 Performance Tuning

### PostgreSQL

```bash
# Optimize for your hardware
# shared_buffers = 25% of RAM
# effective_cache_size = 75% of RAM
# work_mem = (RAM - shared_buffers) / max_connections
# maintenance_work_mem = 10-20% of RAM
```

### Redis

- [ ] Maxmemory policy optimized
- [ ] Slow log monitored
- [ ] Memory fragmentation checked

### Nginx

- [ ] Worker processes = CPU cores
- [ ] Worker connections optimized
- [ ] Connection keep-alive enabled
- [ ] Buffer sizes appropriate

---

## 🔄 Backup & Recovery

### Backup Strategy

- [ ] Daily full backups scheduled
- [ ] Incremental backups configured
- [ ] Off-site backup copies made
- [ ] Backup retention policy: 30 days minimum

### Backup Procedures

```bash
# Full backup
./backup.sh full

# Database backup
./backup.sh db

# Backup cron job (add to crontab)
0 2 * * * cd /opt/docker/infrastructure && ./backup.sh full >> /var/log/backups.log 2>&1
```

### Recovery Procedures

- [ ] Recovery procedure documented
- [ ] Recovery tested monthly
- [ ] Time to recover estimated
- [ ] Alert on backup failure

---

## 📝 Documentation & Handover

### Documentation

- [ ] Deployment procedure documented
- [ ] Architecture diagram created
- [ ] Configuration options documented
- [ ] Runbooks created for common tasks
- [ ] Troubleshooting guide comprehensive

### Team Knowledge

- [ ] Team trained on deployment
- [ ] Operations manual provided
- [ ] Emergency procedures explained
- [ ] Escalation procedures defined
- [ ] On-call procedures established

### Monitoring & Alerting

- [ ] Monitoring dashboards setup
- [ ] Alert notifications configured
- [ ] Escalation contacts identified
- [ ] Incident response procedure documented

---

## 🔍 Ongoing Maintenance

### Daily Tasks

- [ ] Monitor service health: `./monitor.sh`
- [ ] Check logs for errors
- [ ] Verify backups completed
- [ ] Resource usage within limits

### Weekly Tasks

- [ ] Security updates checked
- [ ] Database optimization: `VACUUM ANALYZE`
- [ ] Backup integrity verified
- [ ] Performance review

### Monthly Tasks

- [ ] Full backup recovery test
- [ ] Security audit
- [ ] Performance tuning review
- [ ] Capacity planning

### Quarterly Tasks

- [ ] Disaster recovery drill
- [ ] Security assessment
- [ ] Architecture review
- [ ] Upgrade planning

---

## 🆘 Emergency Contacts

- [ ] Primary DBA contact: `_____________`
- [ ] Secondary contact: `_____________`
- [ ] Infrastructure lead: `_____________`
- [ ] Security team: `_____________`
- [ ] Escalation procedure: `_____________`

---

## ✅ Final Sign-Off

- [ ] All checklist items completed
- [ ] Deployment approved by: `_____________`
- [ ] Date: `_____________`
- [ ] Notes:

```
_________________________________________________________________

_________________________________________________________________

_________________________________________________________________
```

---

## 📞 Support Resources

- Docker Documentation: https://docs.docker.com/
- PostgreSQL: https://www.postgresql.org/docs/
- Redis: https://redis.io/documentation
- MinIO: https://min.io/docs/
- Centrifugo: https://centrifugo.dev/docs/
- Nginx: https://nginx.org/en/docs/

---

**Last Updated:** 2026-01-20
**Version:** 1.0.0
