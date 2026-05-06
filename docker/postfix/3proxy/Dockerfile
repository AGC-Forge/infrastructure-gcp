FROM alpine:latest

# Install 3proxy dan dependencies
RUN apk add --no-cache wget make gcc libc-dev && \
    wget -O 3proxy.tar.gz https://github.com/3proxy/3proxy/archive/refs/tags/0.9.5.tar.gz && \
    tar -xzf 3proxy.tar.gz && \
    cd 3proxy-0.9.5 && \
    ln -s Makefile.Linux Makefile && \
    make && \
    make install && \
    apk del wget make gcc libc-dev && \
    rm -rf /3proxy* /var/cache/apk/*

# Buat direktori
RUN mkdir -p /etc/3proxy /var/log/3proxy

# HAPUS baris COPY config - karena akan di-generate oleh entrypoint
# COPY docker/3proxy/config/3proxy.cfg /etc/3proxy/3proxy.cfg

# Copy entrypoint script
COPY docker/3proxy/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose ports
EXPOSE 3129 1080

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
CMD ["3proxy", "/etc/3proxy/3proxy.cfg"]