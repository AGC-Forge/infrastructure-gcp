#!/bin/bash

# Create directories
mkdir -p docker/redis/tls docker/postgres/tls

# Generate CA
openssl genrsa -out ca.key 2048
openssl req -new -x509 -days 3650 -key ca.key -out ca.crt \
  -subj "/C=ID/ST=Jakarta/L=Jakarta/O=Local/CN=LocalCA"

# Generate Redis certificates
openssl genrsa -out docker/redis/tls/redis.key 2048
openssl req -new -key docker/redis/tls/redis.key -out redis.csr \
  -subj "/C=ID/ST=Jakarta/L=Jakarta/O=Local/CN=redis.local"
openssl x509 -req -days 365 -in redis.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out docker/redis/tls/redis.crt
cp ca.crt docker/redis/tls/ca.crt
rm redis.csr

# Generate PostgreSQL certificates
openssl genrsa -out docker/postgres/tls/server.key 2048
chmod 600 docker/postgres/tls/server.key
openssl req -new -key docker/postgres/tls/server.key -out server.csr \
  -subj "/C=ID/ST=Jakarta/L=Jakarta/O=Local/CN=postgres.local"
openssl x509 -req -days 365 -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out docker/postgres/tls/server.crt
rm server.csr

# Cleanup
rm ca.key ca.crt ca.srl

echo "Certificates generated successfully!"