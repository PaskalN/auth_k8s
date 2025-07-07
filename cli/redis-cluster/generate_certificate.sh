#!/bin/sh

set -e
cd "$(dirname "$0")"

EXPORT_FILE_PATH="../../tmp/redis-cluster"
CERT_DIR="$EXPORT_FILE_PATH/certificates"

mkdir -p "$CERT_DIR"

# 1. Create a self-signed CA
openssl genrsa -out "$CERT_DIR/ca.key" 4096
openssl req -x509 -new -nodes -key "$CERT_DIR/ca.key" -sha256 -days 3650 \
  -out "$CERT_DIR/ca.crt" -subj "/CN=redis-cluster"

# 2. Generate server key and CSR
openssl genrsa -out "$CERT_DIR/redis.key" 2048
openssl req -new -key "$CERT_DIR/redis.key" -out "$CERT_DIR/redis.csr" -subj "/CN=redis-server"

# 3. Sign the server certificate
openssl x509 -req -in "$CERT_DIR/redis.csr" \
  -CA "$CERT_DIR/ca.crt" -CAkey "$CERT_DIR/ca.key" -CAcreateserial \
  -out "$CERT_DIR/redis.crt" -days 365 -sha256

# 4. Capture outputs in variables
KEY=$(cat "$CERT_DIR/ca.key")
CRT=$(cat "$CERT_DIR/ca.crt")
CSR=$(cat "$CERT_DIR/redis.csr")
SERVER_CRT=$(cat "$CERT_DIR/redis.crt")

EXPORT_FILE_PATH="../../tmp/redis-cluster"

mkdir -p "$EXPORT_FILE_PATH"

cat > "$EXPORT_FILE_PATH/values_secrets.yaml" <<EOF
# Redis TLS Secrets
crt: $(cat "$CERT_DIR/redis.crt" | base64 -w 0)

key: $(cat "$CERT_DIR/redis.key" | base64 -w 0)

ca: $(cat "$CERT_DIR/ca.crt" | base64 -w 0)
EOF

HELM_REDIS_PATH="../../helm/redis-cluster"

cp "$EXPORT_FILE_PATH/values_secrets.yaml" "$HELM_REDIS_PATH"

