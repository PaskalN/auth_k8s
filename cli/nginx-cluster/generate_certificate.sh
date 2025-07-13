#!/bin/sh

set -e
cd "$(dirname "$0")"

EXPORT_FILE_PATH="../../tmp/nginx-cluster"
CERT_DIR="$EXPORT_FILE_PATH/certificates"

mkdir -p "$EXPORT_FILE_PATH"
mkdir -p "$CERT_DIR"

# 1. Create a self-signed CA
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout "$CERT_DIR/server.key" \
  -out "$CERT_DIR/server.crt" \
  -subj "/CN=localhost"

# openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
#   -keyout "$CERT_DIR/server.key" \
#   -out "$CERT_DIR/server.crt" \
#   -config "./server.cnf"

cat > "$EXPORT_FILE_PATH/values_secrets.yaml" <<EOF
# Redis TLS Secrets
server_crt: $(cat "$CERT_DIR/server.crt" | base64 -w 0)

server_key: $(cat "$CERT_DIR/server.key" | base64 -w 0)
EOF

HELM_NGINX_PATH="../../helm/nginx-cluster"

cp "$EXPORT_FILE_PATH/values_secrets.yaml" "$HELM_NGINX_PATH"

