#!/bin/sh

set -e

PORT=${PORT:-6379}
CLUSTER_NODE_TIMEOUT=${CLUSTER_NODE_TIMEOUT:-5000}
POD_INDEX=${POD_NAME_INDEX##*-}
REDIS_NODE_ID=$(expr "$POD_INDEX" + 1)
POD_NAME="${POD_NAME_INDEX%-[0-9]*}"

while true; do
    echo "123"
    sleep 2
done

if [ -z "$MOUNT_POINT" ]; then
    printf "MOUNT_POINT is missing: Please privide value!"
    exit 1
fi

if [ -z "$POD_NAME" ]; then
    printf "POD_NAME is missing: Please privide value!"
    exit 1
fi

if [ -z "$REPLICAS" ]; then
    printf "REPLICAS is missing: Please privide value!"
    exit 1
fi

if [ -z "$CLUSTER_REPLICAS" ]; then
    printf "CLUSTER_REPLICAS is missing: Please privide value!"
    exit 1
fi

if [ -z "$SERVICE_NAME" ]; then
    printf "SERVICE_NAME is missing: Please privide value!"
    exit 1
fi

if [ -z "$NAMESPACE" ]; then
    printf "NAMESPACE is missing: Please privide value!"
    exit 1
fi

if [ -z "$NAMESPACE" ]; then
    printf "NAMESPACE is missing: Please privide value!"
    exit 1
fi

. "$MOUNT_POINT/global_tools.sh"
. "$MOUNT_POINT/cluster_tools.sh"
. "$MOUNT_POINT/orchestrate.sh"
. "$MOUNT_POINT/cluster_health.sh"

print_green "Scale down starting" 1

remove_pod_from_cluster() {
    print_green "Preparing for pod removing: $POD_NAME from Redis cluster..." 1

    IS_MASTER=$(is_master "$REDIS_NODE_ID" "$CLUSTER_REPLICAS")

    # 0. Wait until cluster is ready
    operation_loop

    # 1. If master, move all slots to other masters
    if [ "$IS_MASTER" -eq 1 ]; then
        print_green "Pod is a master. Migrating slots before removal..." 1
        move_all_slots_to_masters
        operation_loop  # wait for migration to complete
    else
        print_green "Pod is not a master. Proceeding with removal..." 1
    fi

    # 2. Delete node from the cluster
    delete_current_cluster_node

    # 3. Rebalance the cluster to ensure fair distribution
    operation_loop
    call_rebalance

    print_green "Pod $POD_NAME removed from Redis cluster successfully." 1
}

remove_pod_from_cluster