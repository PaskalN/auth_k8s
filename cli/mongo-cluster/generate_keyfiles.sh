#!/bin/sh

set -e

cd "$(dirname "$0")"

generate_secret_key() {
    SECRET_KEY=$(openssl rand -base64 756 | base64 | tr -d '\n')
    echo "$SECRET_KEY"
}

generate_base64_random_string() {
    RAND=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1 | base64 | tr -d '\n')
    echo "$RAND"
}

EXPORT_FILE_PATH="../../tmp/mongodb-cluster"
EXPORT_PROJECT_FILE_PATH="../../tmp/start-point"

mkdir -p "$EXPORT_FILE_PATH"
mkdir -p "$EXPORT_PROJECT_FILE_PATH"

KEY=$(generate_secret_key)
USER=$(generate_base64_random_string)
SECRET=$(generate_base64_random_string)

cat <<EOF > "$EXPORT_FILE_PATH/values_secrets.yaml"
# UUIDs
secret_key: "$KEY"
db_user: "$USER"
db_secret: "$SECRET"
EOF

cat <<EOF > "$EXPORT_PROJECT_FILE_PATH/values_mongodb_secrets.yaml"
# UUIDs
mongodb_secret_key: "$KEY"
mongodb_db_user: "$USER"
mongodb_db_secret: "$SECRET"
EOF

HELM_MONGODB_PATH="../../helm/mongodb-cluster"
HELM_START_POINT_PATH="../../helm/start-point"

cp "$EXPORT_FILE_PATH/values_secrets.yaml" "$HELM_MONGODB_PATH"
cp "$EXPORT_PROJECT_FILE_PATH/values_mongodb_secrets.yaml" "$HELM_START_POINT_PATH"
