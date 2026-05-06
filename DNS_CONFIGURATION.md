# DNS Configuration Examples

Untuk mengakses services melalui domain names (bukan localhost), Anda perlu mengkonfigurasi DNS atau hosts file.

## Option 1: Edit /etc/hosts (Linux/Mac) atau C:\Windows\System32\drivers\etc\hosts (Windows)

Tambahkan baris berikut:

```
127.0.0.1   storage.infrastructures.help
127.0.0.1   api-storage.infrastructures.help
127.0.0.1   websocket.infrastructures.help
127.0.0.1   pgadmin.infrastructures.help
```

Kemudian akses melalui:

- https://console-storage.infrastructures.help:9001 (MinIO Console)
- https://api-storage.infrastructures.help:9000 (MinIO API)
- https://websocket.infrastructures.help:8000 (Centrifugo)
- https://pgadmin.infrastructures.help:5050 (PgAdmin)

## Option 2: Gunakan dnsmasq (Linux)

```bash
# Install dnsmasq
sudo apt-get install dnsmasq

# Edit /etc/dnsmasq.conf
address=/infrastructures.help/127.0.0.1
address=/console-storage.infrastructures.help/127.0.0.1
address=/api-storage.infrastructures.help/127.0.0.1
address=/websocket.infrastructures.help/127.0.0.1
address=/pgadmin.infrastructures.help/127.0.0.1
# Restart dnsmasq
sudo systemctl restart dnsmasq
```

## Option 3: Production dengan DNS Provider

Jika menggunakan domain real di production:

1. Update DNS records ke IP server Ubuntu Docker
2. Update domain names di file konfigurasi:
   - `docker/nginx/centrifugo/centrifugo.conf`
   - `docker/nginx/minio/minio-*.conf`
   - `docker/nginx/conf.d/pgadmin.conf`

3. Setup SSL dengan Certbot:

```bash
docker run -it --rm --name certbot \
  -v /path/to/certs:/etc/letsencrypt \
  -v /path/to/www:/var/www/certbot \
  certbot/certbot certonly -d console-storage.infrastructures.help -d api-storage.infrastructures.help -d websocket.infrastructures.help -d pgadmin.infrastructures.help \
```

## Testing

Setelah konfigurasi, test dengan:

```bash
# Test DNS resolution
nslookup console-storage.infrastructures.help

# Test HTTP connection
curl -v http://console-storage.infrastructures.help

# Test HTTPS connection (jika SSL setup)
curl -v https://console-storage.infrastructures.help
```

## Nginx SSL Configuration

Uncomment di docker-compose.yml dan update `docker/nginx/nginx.conf`:

```nginx
server {
    listen 443 ssl http2;
    server_name console-storage.infrastructures.help;

    ssl_certificate /etc/nginx/ssl/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/privkey.pem;

    # ... rest of config
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name console-storage.infrastructures.help;
    return 301 https://$server_name$request_uri;
}
```
