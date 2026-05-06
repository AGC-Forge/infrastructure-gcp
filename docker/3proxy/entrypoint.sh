#!/bin/sh
# docker/3proxy/entrypoint.sh
set -e

# Generate config dari environment variables
cat > /etc/3proxy/3proxy.cfg << EOF
nserver ${PRIMARY_RESOLVER:-8.8.8.8}
nserver ${SECONDARY_RESOLVER:-1.1.1.1}
nscache 65536

timeouts 1 5 30 60 180 1800 15 60

users ${PROXY_LOGIN:-admin}:CL:${PROXY_PASSWORD:-password}

auth strong
allow ${PROXY_LOGIN:-admin}

proxy -p${PROXY_PORT:-3129} -n -a
socks -p${SOCKS_PORT:-1080} -n -a

maxconn ${MAX_CONNECTIONS:-1024}

log /var/log/3proxy/3proxy.log D
logformat "L%d/%m/%Y %H:%M:%S %z %N %U %C %R %Q %e %E"
EOF

echo "Starting 3proxy..."
exec 3proxy /etc/3proxy/3proxy.cfg