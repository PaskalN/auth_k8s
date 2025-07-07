#!/bin/bash

set -e

MOUNT_MOINT="/mongodb-scripts"
PRESTOP_SCRIPT="$MOUNT_MOINT/prestop.js"
JS_TOOLS="$MOUNT_MOINT/tools.js"

. "$MOUNT_MOINT/sh-tools.sh"

remove_from_cluster() {
    CLEAN_USER=$(echo -n "$MONGO_INITDB_ROOT_USERNAME" | tr -d '\n')
    CLEAN_PASS=$(echo -n "$MONGO_INITDB_ROOT_PASSWORD" | tr -d '\n')

    PRIMARY_HOST=$(detect_primary_host)
    POD_DNS="${HOSTNAME}.${SERVICE_NAME}.${NAMESPACE}.svc.cluster.local:${PORT}"

    print_green "Primary host detected: $PRIMARY_HOST" 1    

    RESULT=$(mongosh "mongodb://${CLEAN_USER}:${CLEAN_PASS}@${PRIMARY_HOST}" --quiet --eval "        
        load('${JS_TOOLS}');
        load('${PRESTOP_SCRIPT}');

        removeFromCluster('${POD_DNS}')        
    ")

    printf "%s" "$RESULT"
}

echo "================================="
echo "Removing the node...."
echo "================================="

sleep 2

remove_from_cluster

echo "================================="
echo "Removed"
echo "================================="

sleep 2
