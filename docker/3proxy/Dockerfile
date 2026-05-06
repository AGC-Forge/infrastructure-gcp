FROM alpine:latest

# Install 3proxy
RUN apk add --no-cache 3proxy curl ca-certificates && rm -rf /var/cache/apk/*

# Buat direktori
RUN mkdir -p /etc/3proxy /var/log/3proxy

# Copy entrypoint dan SET PERMISSION SEKALIGUS
COPY docker/3proxy/entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh && \
    chown root:root /entrypoint.sh && \
    ls -la /entrypoint.sh  # Debug: cek permission

# Pastikan shebang benar
RUN head -1 /entrypoint.sh | grep -q '^#!/' || echo "WARNING: No shebang found"

# Set entrypoint dengan explicit path
ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
CMD ["3proxy", "/etc/3proxy/3proxy.cfg"]