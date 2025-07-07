#!/bin/sh

# For Debug
# set -x
set -e

# Check if the current node persists in the cluster
# ==================================================
is_node_in_cluster() {
    port=$1
    output=$(redis-cli -p "$port" cluster info 2>/dev/null | grep cluster_state)

    if echo "$output" | grep -q "ok"; then
        echo "1" 
    else
        echo "0" 
    fi
}

# Once all initial nodes are ready, the last one call
# calls this function. The function setup the initial
# cluster
# ==================================================
setup_initial_cluster() {
    REPLICAS=$1
    SERVICE_NAME=$2
    NAMESPACE=$3
    POD_NAME=$4
    PORT=$5
    CLUSTER_REPLICAS=$6

    INITIAL_NODES=$(construct_initial_node_set "$REPLICAS" "$SERVICE_NAME" "$NAMESPACE" "$POD_NAME")
    INITIAL_NODES_PORT=$(construct_initial_node_set_port "$REPLICAS" "$SERVICE_NAME" "$NAMESPACE" "$POD_NAME" "$PORT")

    printf "\\n⏳ Waiting for Redis nodes to be healthy...\\n";
    for node in $INITIAL_NODES; do
        until redis-cli -h $node ping | grep -q PONG; do
            printf "\\n Waiting for %s... \\n" "$node"
            sleep 2;
        done;
    done;

    print_green "🚀 Creating Redis cluster..." 1;
    print_green 'yes yes | redis-cli --cluster create %s --cluster-replicas %s\\n' "$INITIAL_NODES_PORT" "$CLUSTER_REPLICAS" 2
    
    yes yes | redis-cli --cluster create $INITIAL_NODES_PORT --cluster-replicas "$CLUSTER_REPLICAS"
   
    print_green "✅ Redis cluster initialized!" 1
}

# Start point for initial cluster setup
# ==================================================
init_initial_node() {
    REDIS_NODE_ID=$1
    CLUSTER_REPLICAS=$2
    REPLICAS=$3
    SERVICE_NAME=$4
    NAMESPACE=$5
    POD_NAME=$6
    PORT=$7

    print_green "Starting Initial Node script ...." 1

    in_cluster=$(is_node_in_cluster "$PORT" "$REDIS_NODE_ID" "$CLUSTER_REPLICAS")    

    [ "$REDIS_NODE_ID" -eq "$REPLICAS" ] && last_initial_node=1 || last_initial_node=0

    print_green "================================"
    print_green "🚀 in_cluster. ${in_cluster}"
    print_green "🚀 last_initial_node ${last_initial_node}"
    print_green "================================"

    # if the node is initial node and is not a part of the cluster yet
    if [ "$in_cluster" -eq 0 ]; then
        # If the cluster is not ready and this is the last node
        # Setup the initial cluster
        if [ "$last_initial_node" -eq 1 ]; then

            print_green "================================"
            print_green "🚀 This is the last node. It will create the initial cluster."
            print_green "⏳ Creating ..."
            print_green "================================"

            setup_initial_cluster "$REPLICAS" "$SERVICE_NAME" "$NAMESPACE" "$POD_NAME" "$PORT" "$CLUSTER_REPLICAS"
        else 
            print_yellow "✅ This is initial node! This node is not the last node in the group. it will wait for the last node to setup the cluster." 1
        fi
    else
        # Else this node is already part of the initial 
        # node group and it was failed or restarted
        # In this case skip, the redis will handle it

        print_yellow "✅ This node is already a part of the cluster." 1
    fi
}
