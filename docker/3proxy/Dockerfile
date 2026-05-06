# docker/3proxy/Dockerfile
FROM alpine:latest

# Install 3proxy langsung dari repo alpine (gak perlu compile source)
RUN apk add --no-cache \
    3proxy \
    curl \
    ca-certificates \
    && rm -rf /var/cache/apk/*

# Buat direktori yang diperlukan
RUN mkdir -p /etc/3proxy /var/log/3proxy

# Copy entrypoint script
COPY docker/3proxy/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose ports
EXPOSE 3129 1080

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
CMD ["3proxy", "/etc/3proxy/3proxy.cfg"]