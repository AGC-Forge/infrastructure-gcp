#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

PUBLIC_CERT_MODE="${PUBLIC_CERT_MODE:-letsencrypt}" # letsencrypt, self-signed, or none
LETSENCRYPT_EMAIL="${LETSENCRYPT_EMAIL:-}"
BASE_DOMAIN="${BASE_DOMAIN:-localtunnel.it.com}"
INSTALL_PREREQS="${INSTALL_PREREQS:-false}"
SKIP_NGINX="${SKIP_NGINX:-false}"
SKIP_DOCKER="${SKIP_DOCKER:-false}"
ENABLE_3PROXY_NGINX="${ENABLE_3PROXY_NGINX:-false}"
USE_PUBLIC_MAIL_CERT="${USE_PUBLIC_MAIL_CERT:-true}"

ACME_WEBROOT="${ACME_WEBROOT:-/var/www/certbot}"
NGINX_CONF="${NGINX_CONF:-/etc/nginx/conf.d/infrastructure-gcp.conf}"
NGINX_SSL_DIR="${NGINX_SSL_DIR:-/etc/nginx/ssl}"
LOCAL_CERT_DIR="${LOCAL_CERT_DIR:-$ROOT_DIR/local-certs}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
  cat <<'EOF'
Usage:
  scripts/install-infrastructure.sh [options]

Options:
  --self-signed          Use local self-signed certs for public Nginx domains.
  --no-public-ssl        Configure Nginx HTTP only; do not request public certs.
  --skip-nginx           Only prepare certs and Docker services.
  --skip-docker          Only prepare certs and Nginx.
  --install-prereqs      Install nginx/certbot/docker dependencies via apt when missing.
  -h, --help             Show this help.

Environment overrides:
  LETSENCRYPT_EMAIL=superadmin@localtunnel.it.com
  BASE_DOMAIN=localtunnel.it.com
  MINIO_API_DOMAIN=api-storage.localtunnel.it.com
  MINIO_CONSOLE_DOMAIN=console-storage.localtunnel.it.com
  CENTRIFUGO_DOMAIN=websocket.localtunnel.it.com
  PGADMIN_DOMAIN=pgadmin.localtunnel.it.com
  SUPABASE_API_DOMAIN=api-supabase.localtunnel.it.com
  SUPABASE_STUDIO_DOMAIN=studio-supabase.localtunnel.it.com
  SUPABASE_REALTIME_DOMAIN=realtime-supabase.localtunnel.it.com
  MAILADMIN_DOMAIN=mailadmin.localtunnel.it.com
  WEBMAIL_DOMAIN=webmail.localtunnel.it.com
  MAIL_HOSTNAME=mail.localtunnel.it.com
  USE_PUBLIC_MAIL_CERT=true
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --self-signed) PUBLIC_CERT_MODE="self-signed" ;;
    --no-public-ssl) PUBLIC_CERT_MODE="none" ;;
    --skip-nginx) SKIP_NGINX="true" ;;
    --skip-docker) SKIP_DOCKER="true" ;;
    --install-prereqs) INSTALL_PREREQS="true" ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
  shift
done

info() { echo -e "${BLUE}==>${NC} $*"; }
ok() { echo -e "${GREEN}OK:${NC} $*"; }
warn() { echo -e "${YELLOW}WARN:${NC} $*"; }
fail() { echo -e "${RED}ERROR:${NC} $*" >&2; exit 1; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Command '$1' belum tersedia."
}

sudo_write() {
  local target="$1"
  sudo mkdir -p "$(dirname "$target")"
  sudo tee "$target" >/dev/null
}

env_get() {
  local key="$1"
  local fallback="${2:-}"
  if [[ ! -f .env ]]; then
    printf '%s' "$fallback"
    return
  fi

  local line
  line="$(grep -E "^[[:space:]]*${key}=" .env | tail -n 1 || true)"
  if [[ -z "$line" ]]; then
    printf '%s' "$fallback"
    return
  fi

  local value="${line#*=}"
  value="${value%%#*}"
  value="$(printf '%s' "$value" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g; s/^"//; s/"$//; s/^'\''//; s/'\''$//')"
  printf '%s' "$value"
}

host_from_url() {
  local url="$1"
  url="${url#http://}"
  url="${url#https://}"
  url="${url%%/*}"
  printf '%s' "$url"
}

compose_cmd() {
  if docker compose version >/dev/null 2>&1; then
    docker compose "$@"
  elif command -v docker-compose >/dev/null 2>&1; then
    docker-compose "$@"
  else
    fail "Docker Compose belum tersedia."
  fi
}

install_prereqs_if_requested() {
  [[ "$INSTALL_PREREQS" == "true" ]] || return
  need_cmd sudo

  if command -v apt-get >/dev/null 2>&1; then
    info "Installing prerequisite packages with apt."
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl openssl nginx certbot python3-certbot-nginx docker.io docker-compose-plugin
    sudo systemctl enable --now docker
    sudo systemctl enable --now nginx
  else
    fail "--install-prereqs saat ini hanya mendukung host berbasis Debian/Ubuntu."
  fi
}

detect_domains() {
  MINIO_API_DOMAIN="${MINIO_API_DOMAIN:-$(host_from_url "$(env_get MINIO_SERVER_URL "https://api-storage.$BASE_DOMAIN")")}"
  MINIO_CONSOLE_DOMAIN="${MINIO_CONSOLE_DOMAIN:-$(host_from_url "$(env_get MINIO_BROWSER_REDIRECT_URL "https://console-storage.$BASE_DOMAIN")")}"
  CENTRIFUGO_DOMAIN="${CENTRIFUGO_DOMAIN:-websocket.$BASE_DOMAIN}"
  PGADMIN_DOMAIN="${PGADMIN_DOMAIN:-pgadmin.$BASE_DOMAIN}"
  SUPABASE_API_DOMAIN="${SUPABASE_API_DOMAIN:-$(host_from_url "$(env_get SUPABASE_PUBLIC_URL "https://api-supabase.$BASE_DOMAIN")")}"
  SUPABASE_STUDIO_DOMAIN="${SUPABASE_STUDIO_DOMAIN:-studio-supabase.$BASE_DOMAIN}"
  SUPABASE_REALTIME_DOMAIN="${SUPABASE_REALTIME_DOMAIN:-realtime-supabase.$BASE_DOMAIN}"
  MAILADMIN_DOMAIN="${MAILADMIN_DOMAIN:-mailadmin.$BASE_DOMAIN}"
  WEBMAIL_DOMAIN="${WEBMAIL_DOMAIN:-webmail.$BASE_DOMAIN}"
  MAIL_HOSTNAME="${MAIL_HOSTNAME:-$(env_get MAIL_HOSTNAME "mail.$BASE_DOMAIN")}"
  PROXY_DOMAIN="${PROXY_DOMAIN:-proxy.$BASE_DOMAIN}"

  PUBLIC_DOMAINS=(
    "$MINIO_API_DOMAIN"
    "$MINIO_CONSOLE_DOMAIN"
    "$CENTRIFUGO_DOMAIN"
    "$PGADMIN_DOMAIN"
    "$SUPABASE_API_DOMAIN"
    "$SUPABASE_STUDIO_DOMAIN"
    "$SUPABASE_REALTIME_DOMAIN"
    "$MAILADMIN_DOMAIN"
    "$WEBMAIL_DOMAIN"
  )

  if [[ "$ENABLE_3PROXY_NGINX" == "true" ]]; then
    PUBLIC_DOMAINS+=("$PROXY_DOMAIN")
  fi

  CERTBOT_DOMAINS=("${PUBLIC_DOMAINS[@]}" "$MAIL_HOSTNAME")
}

generate_cert() {
  local cert_name="$1"
  local common_name="$2"
  shift 2
  local out_dir="$1"
  shift
  local cert="$out_dir/$cert_name.crt"
  local key="$out_dir/$cert_name.key"
  local csr="$out_dir/$cert_name.csr"
  local ext="$out_dir/$cert_name.ext"

  mkdir -p "$out_dir"
  if [[ -f "$cert" && -f "$key" ]]; then
    ok "Certificate exists: $cert"
    return
  fi

  openssl genrsa -out "$key" 2048 >/dev/null 2>&1
  openssl req -new -key "$key" -out "$csr" -subj "/C=ID/ST=Jakarta/L=Jakarta/O=Infrastructure/CN=$common_name" >/dev/null 2>&1

  {
    echo "authorityKeyIdentifier=keyid,issuer"
    echo "basicConstraints=CA:FALSE"
    echo "keyUsage=digitalSignature,keyEncipherment"
    echo "extendedKeyUsage=serverAuth,clientAuth"
    echo "subjectAltName=@alt_names"
    echo "[alt_names]"
    local index=1
    for name in "$@"; do
      echo "DNS.$index=$name"
      index=$((index + 1))
    done
    echo "IP.1=127.0.0.1"
  } > "$ext"

  openssl x509 -req -days 825 -in "$csr" \
    -CA "$LOCAL_CERT_DIR/ca.crt" \
    -CAkey "$LOCAL_CERT_DIR/ca.key" \
    -CAcreateserial \
    -out "$cert" \
    -extfile "$ext" >/dev/null 2>&1

  rm -f "$csr" "$ext"
  chmod 600 "$key"
  chmod 644 "$cert"
  ok "Generated certificate: $cert"
}

generate_local_certs() {
  need_cmd openssl
  info "Generating local/internal TLS certificates."
  mkdir -p "$LOCAL_CERT_DIR" docker/redis/tls docker/postgres/tls docker/mail/tls docker/dovecot

  if [[ ! -f "$LOCAL_CERT_DIR/ca.key" || ! -f "$LOCAL_CERT_DIR/ca.crt" ]]; then
    openssl genrsa -out "$LOCAL_CERT_DIR/ca.key" 4096 >/dev/null 2>&1
    openssl req -new -x509 -days 3650 \
      -key "$LOCAL_CERT_DIR/ca.key" \
      -out "$LOCAL_CERT_DIR/ca.crt" \
      -subj "/C=ID/ST=Jakarta/L=Jakarta/O=Infrastructure/CN=Infrastructure Local CA" >/dev/null 2>&1
    chmod 600 "$LOCAL_CERT_DIR/ca.key"
    chmod 644 "$LOCAL_CERT_DIR/ca.crt"
  fi

  generate_cert redis redis.local docker/redis/tls redis localhost infrastructure_redis
  cp "$LOCAL_CERT_DIR/ca.crt" docker/redis/tls/ca.crt

  generate_cert server postgres.local docker/postgres/tls postgres localhost infrastructure_postgres
  cp "$LOCAL_CERT_DIR/ca.crt" docker/postgres/tls/ca.crt

  generate_cert mailserver "$MAIL_HOSTNAME" docker/mail/tls "$MAIL_HOSTNAME" postfix dovecot mail localhost infrastructure_postfix infrastructure_dovecot
  cp "$LOCAL_CERT_DIR/ca.crt" docker/mail/tls/ca.crt

  if [[ ! -f docker/dovecot/dovecot-ssl.conf ]]; then
    cat > docker/dovecot/dovecot-ssl.conf <<'EOF'
ssl = required
ssl_cert = </etc/ssl/certs/mailserver.crt
ssl_key = </etc/ssl/private/mailserver.key
ssl_min_protocol = TLSv1.2
EOF
  fi

  cp "$LOCAL_CERT_DIR/ca.crt" "$LOCAL_CERT_DIR/infrastructure-local-ca.crt"
  ok "Local project CA ready: $LOCAL_CERT_DIR/infrastructure-local-ca.crt"
}

install_nginx_challenge_config() {
  info "Installing temporary Nginx ACME challenge config."
  sudo mkdir -p "$ACME_WEBROOT"
  cat <<EOF | sudo_write "$NGINX_CONF"
server {
    listen 80;
    server_name ${CERTBOT_DOMAINS[*]};

    location /.well-known/acme-challenge/ {
        root $ACME_WEBROOT;
    }

    location / {
        return 200 "infrastructure-gcp acme bootstrap\n";
        add_header Content-Type text/plain;
    }
}
EOF
  sudo nginx -t
  sudo systemctl reload nginx
}

request_letsencrypt_certs() {
  [[ "$PUBLIC_CERT_MODE" == "letsencrypt" ]] || return
  need_cmd sudo
  need_cmd certbot

  [[ -n "$LETSENCRYPT_EMAIL" ]] || fail "Set LETSENCRYPT_EMAIL=admin@domain untuk mode Let's Encrypt."

  install_nginx_challenge_config

  for domain in "${CERTBOT_DOMAINS[@]}"; do
    info "Requesting Let's Encrypt certificate for: $domain"
    sudo certbot certonly \
      --webroot \
      -w "$ACME_WEBROOT" \
      --non-interactive \
      --agree-tos \
      --email "$LETSENCRYPT_EMAIL" \
      --keep-until-expiring \
      -d "$domain"
  done

  ok "Let's Encrypt certificate is ready."
}

sync_public_mail_cert() {
  [[ "$PUBLIC_CERT_MODE" == "letsencrypt" ]] || return
  [[ "$USE_PUBLIC_MAIL_CERT" == "true" ]] || return

  local live_dir="/etc/letsencrypt/live/$MAIL_HOSTNAME"
  if [[ ! -f "$live_dir/fullchain.pem" || ! -f "$live_dir/privkey.pem" ]]; then
    warn "Mail Let's Encrypt cert not found at $live_dir; keeping local mail certificate."
    return
  fi

  info "Installing public mail certificate into Docker mail TLS mount."
  sudo cp "$live_dir/fullchain.pem" docker/mail/tls/mailserver.crt
  sudo cp "$live_dir/privkey.pem" docker/mail/tls/mailserver.key
  sudo chmod 644 docker/mail/tls/mailserver.crt
  sudo chmod 600 docker/mail/tls/mailserver.key
}

generate_public_self_signed_cert() {
  [[ "$PUBLIC_CERT_MODE" == "self-signed" ]] || return
  need_cmd sudo
  info "Generating self-signed public Nginx certificate."

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  local ext="$tmp_dir/infrastructure-public.ext"
  {
    echo "subjectAltName=@alt_names"
    echo "[alt_names]"
    local index=1
    for domain in "${CERTBOT_DOMAINS[@]}"; do
      echo "DNS.$index=$domain"
      index=$((index + 1))
    done
  } > "$ext"

  sudo mkdir -p "$NGINX_SSL_DIR"
  sudo openssl req -x509 -newkey rsa:4096 -nodes -days 825 \
    -keyout "$NGINX_SSL_DIR/infrastructure-public.key" \
    -out "$NGINX_SSL_DIR/infrastructure-public.crt" \
    -subj "/C=ID/ST=Jakarta/L=Jakarta/O=Infrastructure/CN=${PUBLIC_DOMAINS[0]}" \
    -extfile "$ext" >/dev/null 2>&1
  rm -rf "$tmp_dir"
  ok "Self-signed Nginx cert ready: $NGINX_SSL_DIR/infrastructure-public.crt"
}

ssl_pair_for_domain() {
  local domain="$1"
  if [[ "$PUBLIC_CERT_MODE" == "letsencrypt" ]]; then
    echo "    ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;"
    echo "    ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;"
    echo "    ssl_protocols TLSv1.2 TLSv1.3;"
    echo "    ssl_prefer_server_ciphers off;"
  else
    echo "    ssl_certificate $NGINX_SSL_DIR/infrastructure-public.crt;"
    echo "    ssl_certificate_key $NGINX_SSL_DIR/infrastructure-public.key;"
    echo "    ssl_protocols TLSv1.2 TLSv1.3;"
  fi
}

server_block() {
  local domain="$1"
  local upstream="$2"
  local websocket="${3:-false}"
  local max_body="${4:-100M}"

  cat <<EOF
server {
    listen 80;
    server_name $domain;

    location /.well-known/acme-challenge/ {
        root $ACME_WEBROOT;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name $domain;
$(ssl_pair_for_domain "$domain")

    client_max_body_size $max_body;
    proxy_connect_timeout 60s;
    proxy_send_timeout 300s;
    proxy_read_timeout 300s;

    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    location / {
        proxy_pass $upstream;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
EOF
  if [[ "$websocket" == "true" ]]; then
    cat <<'EOF'
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_buffering off;
EOF
  fi
  cat <<EOF
    }
}

EOF
}

install_nginx_final_config() {
  [[ "$SKIP_NGINX" == "true" ]] && return
  need_cmd sudo
  need_cmd nginx

  if [[ "$PUBLIC_CERT_MODE" == "none" ]]; then
    info "Installing HTTP-only Nginx proxy config."
  else
    info "Installing HTTPS Nginx reverse proxy config."
  fi

  local tmp_conf
  tmp_conf="$(mktemp)"

  if [[ "$PUBLIC_CERT_MODE" == "none" ]]; then
    {
      echo "# Generated by scripts/install-infrastructure.sh"
      server_block_http_only "$MINIO_API_DOMAIN" "http://127.0.0.1:9000" "false" "0"
      server_block_http_only "$MINIO_CONSOLE_DOMAIN" "http://127.0.0.1:9001" "true" "0"
      server_block_http_only "$CENTRIFUGO_DOMAIN" "http://127.0.0.1:8000" "true" "100M"
      server_block_http_only "$PGADMIN_DOMAIN" "http://127.0.0.1:5050" "true" "100M"
      server_block_http_only "$SUPABASE_API_DOMAIN" "http://127.0.0.1:8001" "true" "100M"
      server_block_http_only "$SUPABASE_STUDIO_DOMAIN" "http://127.0.0.1:3000" "true" "50M"
      server_block_http_only "$SUPABASE_REALTIME_DOMAIN" "http://127.0.0.1:8001" "true" "50M"
      server_block_http_only "$MAILADMIN_DOMAIN" "http://127.0.0.1:8085" "false" "50M"
      server_block_http_only "$WEBMAIL_DOMAIN" "http://127.0.0.1:8086" "false" "50M"
      [[ "$ENABLE_3PROXY_NGINX" == "true" ]] && server_block_http_only "$PROXY_DOMAIN" "http://127.0.0.1:3129" "true" "10M"
    } > "$tmp_conf"
  else
    {
      echo "# Generated by scripts/install-infrastructure.sh"
      server_block "$MINIO_API_DOMAIN" "http://127.0.0.1:9000" "false" "0"
      server_block "$MINIO_CONSOLE_DOMAIN" "http://127.0.0.1:9001" "true" "0"
      server_block "$CENTRIFUGO_DOMAIN" "http://127.0.0.1:8000" "true" "100M"
      server_block "$PGADMIN_DOMAIN" "http://127.0.0.1:5050" "true" "100M"
      server_block "$SUPABASE_API_DOMAIN" "http://127.0.0.1:8001" "true" "100M"
      server_block "$SUPABASE_STUDIO_DOMAIN" "http://127.0.0.1:3000" "true" "50M"
      server_block "$SUPABASE_REALTIME_DOMAIN" "http://127.0.0.1:8001" "true" "50M"
      server_block "$MAILADMIN_DOMAIN" "http://127.0.0.1:8085" "false" "50M"
      server_block "$WEBMAIL_DOMAIN" "http://127.0.0.1:8086" "false" "50M"
      [[ "$ENABLE_3PROXY_NGINX" == "true" ]] && server_block "$PROXY_DOMAIN" "http://127.0.0.1:3129" "true" "10M"
    } > "$tmp_conf"
  fi

  sudo mkdir -p "$(dirname "$NGINX_CONF")"
  sudo cp "$tmp_conf" "$NGINX_CONF"
  rm -f "$tmp_conf"
  sudo nginx -t
  sudo systemctl reload nginx
  ok "Nginx config installed: $NGINX_CONF"
}

server_block_http_only() {
  local domain="$1"
  local upstream="$2"
  local websocket="${3:-false}"
  local max_body="${4:-100M}"

  cat <<EOF
server {
    listen 80;
    server_name $domain;
    client_max_body_size $max_body;

    location /.well-known/acme-challenge/ {
        root $ACME_WEBROOT;
    }

    location / {
        proxy_pass $upstream;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
EOF
  if [[ "$websocket" == "true" ]]; then
    cat <<'EOF'
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_buffering off;
EOF
  fi
  cat <<EOF
    }
}

EOF
}

deploy_docker() {
  [[ "$SKIP_DOCKER" == "true" ]] && return
  need_cmd docker

  [[ -f .env ]] || fail ".env belum ada. Jalankan scripts/setup.sh atau buat .env dulu."

  info "Building and starting Docker Compose services."
  compose_cmd build
  compose_cmd up -d

  info "Waiting for containers to initialize."
  sleep 15
  compose_cmd ps
}

print_summary() {
  local scheme="https"
  local realtime_scheme="wss"
  if [[ "$PUBLIC_CERT_MODE" == "none" ]]; then
    scheme="http"
    realtime_scheme="ws"
  fi

  cat <<EOF

Installed endpoints:
  MinIO API:         $scheme://$MINIO_API_DOMAIN
  MinIO Console:     $scheme://$MINIO_CONSOLE_DOMAIN
  Centrifugo:        $scheme://$CENTRIFUGO_DOMAIN
  PgAdmin:           $scheme://$PGADMIN_DOMAIN
  Supabase API:      $scheme://$SUPABASE_API_DOMAIN
  Supabase Studio:   $scheme://$SUPABASE_STUDIO_DOMAIN
  Supabase Realtime: $realtime_scheme://$SUPABASE_REALTIME_DOMAIN
  Mail Admin:        $scheme://$MAILADMIN_DOMAIN
  Webmail:           $scheme://$WEBMAIL_DOMAIN

Local certs for projects:
  CA certificate:    $LOCAL_CERT_DIR/infrastructure-local-ca.crt
  Redis TLS:         $ROOT_DIR/docker/redis/tls
  PostgreSQL TLS:    $ROOT_DIR/docker/postgres/tls
  Mail TLS:          $ROOT_DIR/docker/mail/tls

EOF
}

main() {
  install_prereqs_if_requested
  detect_domains

  info "Public certificate mode: $PUBLIC_CERT_MODE"
  info "Public domains: ${PUBLIC_DOMAINS[*]}"

  generate_local_certs

  if [[ "$SKIP_NGINX" != "true" ]]; then
    if [[ "$PUBLIC_CERT_MODE" == "letsencrypt" ]]; then
      request_letsencrypt_certs
      sync_public_mail_cert
    elif [[ "$PUBLIC_CERT_MODE" == "self-signed" ]]; then
      generate_public_self_signed_cert
    fi
  fi

  deploy_docker
  install_nginx_final_config
  print_summary
}

main "$@"
