#!/bin/bash

set -e



MOUNT_MOINT="/mongodb-scripts"
ADD_NODE_SCRIPT="$MOUNT_MOINT/add_node.js"
ADD_INIT_CLUSTER_SCRIPT="$MOUNT_MOINT/init_cluster.js"
INIT_TOOLS_JS="$MOUNT_MOINT/tools.js"

. "$MOUNT_MOINT/sh-tools.sh"

print_green "CLUSTER INIT BEGIN!" 1

sleep 10

CLEAN_USER=$(echo -n "$MONGO_INITDB_ROOT_USERNAME" | tr -d '\n')
CLEAN_PASS=$(echo -n "$MONGO_INITDB_ROOT_PASSWORD" | tr -d '\n')

add_to_cluster() {

    print_green "ADDING NODE..." 1

    POD_DNS="${HOSTNAME}.${SERVICE_NAME}.${NAMESPACE}.svc.cluster.local"
    
    CLUSTER_DNS=$(get_cluster_dns_set)
    
    if echo "$CLUSTER_DNS" | grep -wq "$POD_DNS"; then
        print_green "The node is part of the cluster." 1
        return 0
    fi

    INITIAL_CLUSTER_DNS=$(get_initial_dns_set)
    if echo "$INITIAL_CLUSTER_DNS" | grep -wq "$POD_DNS:$PORT"; then
        print_green "The node is part of the initial cluster set. Setup will be ready soon." 1
        return 0
    fi

    print_yellow "The node is not a part of the initial cluster set and it is not a part of the current cluster. It will be added to the cluster." 1
    PRIMARY_HOST=$(detect_primary_host)
    print_green "Primary host detected: $PRIMARY_HOST" 1

    MAX_RETRIES=5
    RETRY_COUNT=0

    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        RESULT=$(mongosh "mongodb://${CLEAN_USER}:${CLEAN_PASS}@${PRIMARY_HOST}" --eval "
            const path = \"${ADD_NODE_SCRIPT}\";
            const tools_path = \"${INIT_TOOLS_JS}\";

            console.log('Loading: ' + tools_path);
            load(tools_path);

            console.log('Loading: ' + path);
            load(path);

            add_node('${SERVICE_NAME}', '${NAMESPACE}', ${PORT});
        ")

        case "$RESULT" in
            *success*|*exists*)
                print_green "Replica set membership check done." 1
                break
                ;;
            *)
                print_yellow "Add failed, retrying in 10 seconds..." 1
                sleep 10

                RETRY_COUNT=$((RETRY_COUNT + 1))
                ;;
        esac
    done

    if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then    
        print_red "Failed to add node to replica set after $MAX_RETRIES attempts." 1
        return 1
    fi
}

init() {

    CLUSTER_DNS=$(get_cluster_dns_set)

    if [ -z "$CLUSTER_DNS" ]; then
        print_green "CLUSTER INITIALIZING..." 1

        mongosh --eval "
            const path = \"${ADD_INIT_CLUSTER_SCRIPT}\";
            const tools_path = \"${INIT_TOOLS_JS}\";

            console.log('Loading: ' + tools_path);
            load(tools_path);

            console.log('Loading: ' + path);
            load(path);

            init('${CLUSTER_ID}', '${REPLICAS}', '${POD_NAME}', '${SERVICE_NAME}', '${NAMESPACE}', '${PORT}', '${CLEAN_USER}', '${CLEAN_PASS}')
        "
    fi
}

# START
init

# RECHECK
add_to_cluster
