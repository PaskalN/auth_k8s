#!/bin/sh

set -e

cd "$(dirname "$0")"

generate_uuid_values() {
    CONTROLLER_UUIDs=""
    SEP=""

    i=1
    while [ "$i" -le 50 ]; do
        UUID=$(openssl rand 16 | base64 | tr -d '=' | tr '/+' '_-')
        CONTROLLER_UUIDs="${CONTROLLER_UUIDs}${SEP}${i}@${UUID}"
        i=$((i + 1))
        SEP=","
    done

    echo "$CONTROLLER_UUIDs"
}

generate_cluster_uuid() {
    UUID=$(openssl rand 16 | base64 | tr -d '=' | tr '/+' '_-')
    echo "$UUID"
}

EXPORT_FILE_PATH="../../../tmp/kafka-cluster"

mkdir -p "$EXPORT_FILE_PATH"

cat <<EOF > "$EXPORT_FILE_PATH/values_uuids.yaml"
# UUIDs
controller_uuids: $(generate_uuid_values)
cluster_id: $(generate_cluster_uuid)
EOF

HELM_KAFKA_CONTROLLER_PATH="../../../helm/kafka-controller"
HELM_KAFKA_BROKER_PATH="../../../helm/kafka-broker"

cp "$EXPORT_FILE_PATH/values_uuids.yaml" "$HELM_KAFKA_CONTROLLER_PATH"
cp "$EXPORT_FILE_PATH/values_uuids.yaml" "$HELM_KAFKA_BROKER_PATH"