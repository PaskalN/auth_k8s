#!/bin/sh

set -e

PORT=${PORT:-6379}
CLUSTER_NODE_TIMEOUT=${CLUSTER_NODE_TIMEOUT:-5000}
POD_INDEX=${POD_NAME_INDEX##*-}
REDIS_NODE_ID=$(expr "$POD_INDEX" + 1)
POD_NAME="${POD_NAME_INDEX%-[0-9]*}"

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
. "$MOUNT_POINT/default_cluster.sh"
. "$MOUNT_POINT/cluster_scaling.sh"
. "$MOUNT_POINT/init_cluster.sh"

print_green "INTITIALIZING ...." 1

init "$REDIS_NODE_ID" "$CLUSTER_REPLICAS" "$REPLICAS" "$SERVICE_NAME" "$NAMESPACE" "$POD_NAME" "$PORT" & 

redis-server --port "$PORT" --cluster-enabled yes --cluster-config-file nodes.conf --cluster-node-timeout "$CLUSTER_NODE_TIMEOUT" --appendonly yes

