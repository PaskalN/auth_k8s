#!/bin/sh

# For Debug
# set -x
set -e

# This function checks the current node
# is the node a part of the initial
# cluster group
# =====================================
is_initial_node() {
    REDIS_NODE_ID=$1
    REPLICAS=$2

    if [ "$REDIS_NODE_ID" -le "$REPLICAS" ]; then
        echo "1" 
    else
        echo "0"
    fi
}

# The startpoint for initial cluster
# Detects if the node must be initial cluster
# or part of the scaling process
# ============================================
init() {

    REDIS_NODE_ID=$1
    CLUSTER_REPLICAS=$2
    REPLICAS=$3
    SERVICE_NAME=$4
    NAMESPACE=$5
    POD_NAME=$6

    sleep 2

    print_green "==============================================="
    print_green "NODE with parameters:"
    print_green "REDIS_NODE_ID: ${REDIS_NODE_ID}"
    print_green "POD_NAME: ${POD_NAME}"
    print_green "CLUSTER_REPLICAS: ${CLUSTER_REPLICAS}"
    print_green "REPLICAS: ${REPLICAS}"
    print_green "SERVICE_NAME: ${SERVICE_NAME}"
    print_green "NAMESPACE: ${NAMESPACE}"
    print_green "==============================================="

    initial_node=$(is_initial_node "$REDIS_NODE_ID" "$REPLICAS")

    if [ "$initial_node" -eq 1 ]; then
        # If the node is part of the initial group nodes for the initial cluster
        init_initial_node "$@"
    else
        # If not a part of the initial group, we have to treat it like scale node
        max_retries=5
        count=0
        until init_scale_node "$@"; do
            count=$((count + 1))
            echo "init_scale_node failed, retry #$count..."
            if [ "$count" -ge "$max_retries" ]; then
                echo "Max retries reached, exiting."
                exit 1
            fi
            sleep 5  # wait before retrying
        done
    fi
}
