#!/bin/sh

# Generate config from environment variables
cat > /etc/3proxy/3proxy.cfg << EOF
nscache 65536
timeouts 1 5 30 60 180 600 60 60
users ${PROXY_LOGIN:-admin}:CL:${PROXY_PASSWORD:-password}
auth strong
allow ${PROXY_LOGIN:-admin}

# HTTP Proxy
proxy -p${PROXY_PORT:-3129} -i0.0.0.0 -e0.0.0.0

# SOCKS Proxy
socks -p${SOCKS_PORT:-1080} -i0.0.0.0 -e0.0.0.0

# Logging
log /var/log/3proxy/3proxy.log D
logformat "- +_L%t.%. %N.%p %E %U %C:%c %R:%r %O %I %h %T"
rotate 30
flush
EOF

echo "=== 3proxy Configuration Generated ==="
cat /etc/3proxy/3proxy.cfg
echo "======================================"

# Execute 3proxy
exec "$@"