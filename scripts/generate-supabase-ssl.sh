#!/bin/bash

# Create directories
mkdir -p nginx/ssl

# Generate root CA (if not exists)
if [ ! -f nginx/ssl/ca.key ]; then
    openssl genrsa -out nginx/ssl/ca.key 2048
    openssl req -new -x509 -days 3650 -key nginx/ssl/ca.key -out nginx/ssl/ca.crt \
        -subj "/C=ID/ST=Jakarta/L=Jakarta/O=LocalDev/CN=Local CA Root"
fi

# Function to generate certificate for domain
generate_cert() {
    local DOMAIN=$1
    local NAME=$2
    
    # Generate private key
    openssl genrsa -out nginx/ssl/${NAME}.key 2048
    
    # Generate CSR
    openssl req -new -key nginx/ssl/${NAME}.key -out nginx/ssl/${NAME}.csr \
        -subj "/C=ID/ST=Jakarta/L=Jakarta/O=LocalDev/CN=${DOMAIN}"
    
    # Generate certificate with SAN
    cat > nginx/ssl/${NAME}.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = ${DOMAIN}
DNS.2 = *.${DOMAIN}
DNS.3 = localhost
IP.1 = 127.0.0.1
EOF
    
    openssl x509 -req \
        -in nginx/ssl/${NAME}.csr \
        -CA nginx/ssl/ca.crt \
        -CAkey nginx/ssl/ca.key \
        -CAcreateserial \
        -out nginx/ssl/${NAME}.crt \
        -days 365 \
        -extfile nginx/ssl/${NAME}.ext
    
    # Cleanup
    rm nginx/ssl/${NAME}.csr nginx/ssl/${NAME}.ext
    
    echo "Certificate generated for ${DOMAIN}"
}

# Generate certificates for Supabase subdomains
generate_cert "api-supabase.localtunnel.it.com" "api-supabase"
generate_cert "studio-supabase.localtunnel.it.com" "studio-supabase"
generate_cert "realtime-supabase.localtunnel.it.com" "realtime-supabase"

# Set permissions
chmod 600 nginx/ssl/*.key
chmod 644 nginx/ssl/*.crt

echo ""
echo "SSL certificates generated successfully!"
echo "CA Certificate location: nginx/ssl/ca.crt"
echo "Add CA certificate to your browser/system for HTTPS without warnings."