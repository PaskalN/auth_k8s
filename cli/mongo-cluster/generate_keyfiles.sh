#!/bin/sh

set -e

cd "$(dirname "$0")"

generate_secret_key() {
    SECRET_KEY=$(openssl rand -base64 756 | base64 | tr -d '\n')
    echo "$SECRET_KEY"
}

generate_base64_random_string() {
    RAND=$(openssl rand -base64 16 | base64 | tr -d '\n')
    echo "$RAND"
}

EXPORT_FILE_PATH="../../tmp/mongodb-cluster"

mkdir -p "$EXPORT_FILE_PATH"

cat <<EOF > "$EXPORT_FILE_PATH/values_secrets.yaml"
# UUIDs
secret_key: $(generate_secret_key)
db_user: $(generate_base64_random_string)
db_secret: $(generate_base64_random_string)
EOF

HELM_MONGODB_PATH="../../helm/mongodb-cluster"

cp "$EXPORT_FILE_PATH/values_secrets.yaml" "$HELM_MONGODB_PATH"