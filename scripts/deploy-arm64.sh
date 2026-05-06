#!/bin/bash
# scripts/deploy-arm64.sh

echo "🚀 Deploying for ARM64 architecture..."

# Clean old stuff
docker-compose down -v
docker system prune -a -f

# Create directories
mkdir -p docker/{postgres/scripts,redis/tls,3proxy,centrifugo}
mkdir -p docker/supabase/kong

# Generate init script
cat > docker/postgres/scripts/01-init.sql << 'EOF'
CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS storage;
CREATE SCHEMA IF NOT EXISTS _analytics;
CREATE SCHEMA IF NOT EXISTS _realtime;
CREATE SCHEMA IF NOT EXISTS graphql_public;

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'anon') THEN
        CREATE ROLE anon NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'authenticated') THEN
        CREATE ROLE authenticated NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'service_role') THEN
        CREATE ROLE service_role NOLOGIN;
    END IF;
END $$;

GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON SCHEMA auth TO anon, authenticated, service_role;
GRANT ALL ON SCHEMA storage TO anon, authenticated, service_role;
EOF

# Generate simple Kong config
cat > docker/supabase/kong/kong.yml << 'EOF'
_format_version: "2.1"
services:
  - name: auth-v1
    url: http://supabase-auth:9999/
    routes:
      - name: auth-v1-route
        strip_path: true
        paths:
          - /auth/v1
    plugins:
      - name: cors
  - name: rest-v1
    url: http://supabase-rest:3000/
    routes:
      - name: rest-v1-route
        strip_path: true
        paths:
          - /rest/v1
    plugins:
      - name: cors
  - name: storage-v1
    url: http://supabase-storage:5000/
    routes:
      - name: storage-v1-route
        strip_path: true
        paths:
          - /storage/v1
    plugins:
      - name: cors
EOF

# Build and start
docker-compose build postgres 3proxy
docker-compose up -d

# Check status
echo "📊 Service status:"
docker-compose ps

echo ""
echo "✅ Deploy complete for ARM64!"
echo "Access points:"
echo "  Supabase Studio: http://localhost:3000"
echo "  MinIO Console:   http://localhost:9001"
echo "  PgAdmin:         http://localhost:5050"
echo "  MailHog:         http://localhost:8025"