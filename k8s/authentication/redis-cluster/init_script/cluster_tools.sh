#!/bin/sh

set -e

# Returns the first healthy node dns from the initial cluster
# ====================================================
# Check
# echo $(get_healthy_cluster_node_dsn) => redis-node-0.redis-service.authentication.svc.cluster.local
get_healthy_cluster_node_dsn() {    
    INITIAL_NODES=$(construct_initial_node_set "$REPLICAS" "$SERVICE_NAME" "$NAMESPACE" "$POD_NAME")
	READY_NODE=""

	while [ -z "$READY_NODE" ]; do
	    for node in $INITIAL_NODES; do
	        if redis-cli -h "$node" ping | grep -q PONG; then
	            READY_NODE=$node
                print_green "Found: $READY_NODE" 1 >&2
	            break
	        fi
	    done
	    
	    if [ -z "$READY_NODE" ]; then
	        print_yellow "No available healty nodes, retrying in 2 seconds..." 1 >&2
	        sleep 2
	    fi
	done

	echo "$node"
}

# Returns the master node dns from the pod froup
# ====================================================
# Check
# echo $(get_group_master_node) => redis-node-8.redis-service.authentication.svc.cluster.local
get_group_master_node() {
    GROUP_SET=$(group_pods "$REDIS_NODE_ID" "$CLUSTER_REPLICAS")
    GROUP_DNS=$(construct_node_set "$GROUP_SET" "$SERVICE_NAME" "$NAMESPACE" "$POD_NAME")

    print_green "GROUP_SET: $GROUP_SET"
    print_green "GROUP_DNS: $GROUP_DNS"

    MASTER_NODE=""
    while [ -z "$MASTER_NODE" ]; do
        for node in $GROUP_DNS; do
            if redis-cli -h "$node" ping | grep -q PONG; then

                NODE_ID=$(redis-cli -h "$node" -p "$PORT" cluster myid)
                ROLE=$(redis-cli -h "$node" -p "$PORT" cluster nodes | awk -v id="$NODE_ID" '$1 == id { print $3 }' | grep master || true)

                if [ -n "$ROLE" ]; then                    
                    MASTER_NODE=$node
                    print_green "Found MASTER: $MASTER_NODE" 1
                    break
                fi
            fi
        done
        
        if [ -z "$MASTER_NODE" ]; then
            print_yellow "No master node available in the group, retrying in 2 seconds..." 1
            sleep 2
        fi
    done

    echo "$MASTER_NODE"
}


# Returns the master ID by providing the master dns
# ====================================================
# Check
# echo $(get_master_node_id) => a8g765s...
get_master_node_id() {
    MASTER_NODE="$1"

    RESULT=$(redis-cli -h "$MASTER_NODE" -p "$PORT" cluster nodes | awk '$3 ~ /master/ { print $1; exit }')
    echo "$RESULT"
}


# Adds new empty master to the cluster by providing pod DNS
# ===========================================================
add_empty_master() {
    POD_DNS="$1"

    MAX_RETRIES=5
    RETRY_DELAY=2  # seconds (initial delay)
    ATTEMPT=1

    INITIAL_NODES=$(construct_initial_node_set "$REPLICAS" "$SERVICE_NAME" "$NAMESPACE" "$POD_NAME")

    while [ "$ATTEMPT" -le "$MAX_RETRIES" ]; do
        CLUSTER_NODE_DNS=$(get_healthy_cluster_node_dsn "$INITIAL_NODES")

        print_green "Attempt $ATTEMPT: Adding empty master $POD_DNS to cluster via $CLUSTER_NODE_DNS:$PORT" 1
        print_green "Adding: $POD_DNS" 1

        if redis-cli --cluster add-node "$POD_DNS" "$CLUSTER_NODE_DNS:$PORT" --cluster-slots 0; then
            print_green "Successfully added node $POD_DNS to the cluster." 1
            return 0
        else
            print_yellow "Failed to add node. Retrying in $RETRY_DELAY seconds..." 1
            sleep "$RETRY_DELAY"
            RETRY_DELAY=$((RETRY_DELAY * 2))  # exponential backoff
            ATTEMPT=$((ATTEMPT + 1))
        fi
    done

    print_red "ERROR: Failed to add node $POD_DNS to the cluster after $MAX_RETRIES attempts." 1
    return 1
}


# Adds new slave\follower\replica to the cluster by providing pod replica DNS
# ===========================================================================
add_replica() {
    REPLICA_POD_DNS="$1"
    MAX_RETRIES=5
    RETRY_DELAY=2  # initial delay in seconds
    ATTEMPT=1

    INITIAL_NODES=$(construct_initial_node_set "$REPLICAS" "$SERVICE_NAME" "$NAMESPACE" "$POD_NAME")

    while [ "$ATTEMPT" -le "$MAX_RETRIES" ]; do
        CLUSTER_NODE_DNS=$(get_healthy_cluster_node_dsn "$INITIAL_NODES")
        GROUP_MASTER_NODE=$(get_group_master_node)
        GROUP_MASTER_NODE_ID=$(get_master_node_id "$GROUP_MASTER_NODE")

        print_green "Attempt $ATTEMPT: Adding replica $REPLICA_POD_DNS to follow $GROUP_MASTER_NODE_ID via $CLUSTER_NODE_DNS:$PORT"

        if redis-cli --cluster add-node "$REPLICA_POD_DNS" "$CLUSTER_NODE_DNS:$PORT" --cluster-slave --cluster-master-id "$GROUP_MASTER_NODE_ID"; then
            print_green "Successfully added replica $REPLICA_POD_DNS to follow master $GROUP_MASTER_NODE_ID" 1
            return 0
        else
            print_yellow "Failed to add replica. Retrying in $RETRY_DELAY seconds..." 1
            sleep "$RETRY_DELAY"
            RETRY_DELAY=$((RETRY_DELAY * 2))  # exponential backoff
            ATTEMPT=$((ATTEMPT + 1))
        fi
    done

    print_yellow "ERROR: Failed to add replica $REPLICA_POD_DNS after $MAX_RETRIES attempts."
    return 1
}


# A special REDIS command, when unexpected error happens.
# ===========================================================================
call_cluster_fix() {
    CLUSTER_NODE_DNS="$1"
    MAX_RETRIES=5
    RETRY_DELAY=5
    ATTEMPT=1

    while [ "$ATTEMPT" -le "$MAX_RETRIES" ]; do
        if redis-cli --cluster fix "$CLUSTER_NODE_DNS:$PORT"; then
            echo "Cluster fix succeeded."
            break
        else
            echo "Cluster fix failed. Retrying in $RETRY_DELAY seconds..."
            sleep "$RETRY_DELAY"
            ATTEMPT=$((ATTEMPT + 1))
        fi
    done

    if [ "$ATTEMPT" -gt "$MAX_RETRIES" ]; then
        echo "Cluster fix failed after $MAX_RETRIES attempts."
        exit 1
    fi
}

# A special REDIS command, for slot rebalancing accross the masters
# ===========================================================================
call_rebalance() {
    INITIAL_NODES=$(construct_initial_node_set "$REPLICAS" "$SERVICE_NAME" "$NAMESPACE" "$POD_NAME")
    MAX_RETRIES=5
    RETRY_DELAY=2  # seconds
    ATTEMPT=1

    while [ "$ATTEMPT" -le "$MAX_RETRIES" ]; do
        CLUSTER_NODE_DNS=$(get_healthy_cluster_node_dsn "$INITIAL_NODES")

        print_green "Attempt $ATTEMPT: Rebalancing cluster via $CLUSTER_NODE_DNS:$PORT" 1

        if redis-cli --cluster rebalance --cluster-use-empty-masters "$CLUSTER_NODE_DNS:$PORT"; then
            print_green "Rebalance succeeded." 1
            return 0
        else
            print_yellow "Rebalance failed. Retrying in $RETRY_DELAY seconds..." 1
            call_cluster_fix "$CLUSTER_NODE_DNS"

            sleep "$RETRY_DELAY"
            RETRY_DELAY=$((RETRY_DELAY * 2))
            ATTEMPT=$((ATTEMPT + 1))
        fi
    done

    print_red "ERROR: Failed to rebalance cluster after $MAX_RETRIES attempts." 1
    return 1
}

get_rest_master_id_list() {
    INITIAL_NODES=$(construct_initial_node_set "$REPLICAS" "$SERVICE_NAME" "$NAMESPACE" "$POD_NAME")
    CLUSTER_NODE_DNS=$(get_healthy_cluster_node_dsn "$INITIAL_NODES")

    RESULT=$(redis-cli -h "$CLUSTER_NODE_DNS" -p "$PORT" cluster nodes | awk -v myid="$MYID" '$3 ~ /master/ && $1 != myid {print $1}')

    echo "$RESULT"
}

get_rest_master_id_list_comma() {
    INITIAL_NODES=$(construct_initial_node_set "$REPLICAS" "$SERVICE_NAME" "$NAMESPACE" "$POD_NAME")
    CLUSTER_NODE_DNS=$(get_healthy_cluster_node_dsn "$INITIAL_NODES")

    RESULT=$(redis-cli -h "$CLUSTER_NODE_DNS" -p "$PORT" cluster nodes | awk -v myid="$MYID" '
        $3 ~ /master/ && $1 != myid { 
            ids = (ids == "" ? $1 : ids "," $1) 
        } 
        END { print ids }
    ')

    echo "$RESULT"
}

get_first_rest_master_id() {
    INITIAL_NODES=$(construct_initial_node_set "$REPLICAS" "$SERVICE_NAME" "$NAMESPACE" "$POD_NAME")
    CLUSTER_NODE_DNS=$(get_healthy_cluster_node_dsn "$INITIAL_NODES")

    FIRST_ID=$(redis-cli -h "$CLUSTER_NODE_DNS" -p "$PORT" cluster nodes | awk -v myid="$MYID" '
        $3 ~ /master/ && $1 != myid { print $1; exit }
    ')

    echo "$FIRST_ID"
}

get_my_node_id() {
    CURRENT_NODE_ID=$(redis-cli -p "$PORT" cluster myid)
    echo "$CURRENT_NODE_ID"
}

move_all_slots_to_masters() {
    MAX_RETRIES=5
    RETRY_DELAY=2  # seconds
    ATTEMPT=1

    while [ "$ATTEMPT" -le "$MAX_RETRIES" ]; do
        MASTER_ID_LIST=$(get_rest_master_id_list_comma)
        CURRENT_MASTER_ID=$(get_my_node_id)

        print_green "Attempt $ATTEMPT: Resharding cluster slots" 1

        if redis-cli --cluster reshard <cluster_node>:6379 --from "$CURRENT_MASTER_ID" --to "$MASTER_ID_LIST" --slots 16500 --yes; then
            print_green "Resharding succeeded." 1
            return 0
        else
            print_yellow "Resharding failed. Retrying in $RETRY_DELAY seconds..." 1
            CLUSTER_NODE_DNS=$(get_healthy_cluster_node_dsn "$INITIAL_NODES")
            call_cluster_fix "$CLUSTER_NODE_DNS"

            sleep "$RETRY_DELAY"
            RETRY_DELAY=$(( RETRY_DELAY * 2 ))
            ATTEMPT=$(( ATTEMPT + 1 ))
        fi
    done

    print_red "ERROR: Failed to reshard master slots after $MAX_RETRIES attempts." 1
    return 1
}

delete_current_cluster_node() {
    MAX_RETRIES=5
    RETRY_DELAY=2  # seconds
    ATTEMPT=1

    # Get your current node ID (the one to delete)
    CURRENT_NODE_ID=$(get_my_node_id)

    while [ "$ATTEMPT" -le "$MAX_RETRIES" ]; do
        # Get a healthy cluster node to connect to (not the node to delete)
        CLUSTER_NODE_DNS=$(get_healthy_cluster_node_dsn)

        if redis-cli --cluster del-node "$CLUSTER_NODE_DNS:$PORT" "$CURRENT_NODE_ID"; then
            print_green "Node deleted successfully." 1
            return 0
        else
            print_yellow "Node delete process failed. Retrying in $RETRY_DELAY seconds..." 1
            call_cluster_fix "$CLUSTER_NODE_DNS"

            sleep "$RETRY_DELAY"
            RETRY_DELAY=$(( RETRY_DELAY * 2 ))
            ATTEMPT=$(( ATTEMPT + 1 ))
        fi
    done

    print_red "ERROR: Failed to delete the node after $MAX_RETRIES attempts." 1
    return 1
}
