#!/bin/sh

set -e

is_cluster_busy() {
    CLUSTER_NODE_DNS=$(get_healthy_cluster_node_dsn)
    CLUSTER_NODES=$(redis-cli -h "$CLUSTER_NODE_DNS" -p "$PORT" cluster nodes)

    # Check if any node is in slot migration or import
    if echo "$CLUSTER_NODES" | grep -qE '\[.*(importing|migrating).*]'; then
        return 0
    else        
        return 1
    fi
}

# Returns 0 | 1 if the cluster is healty (all pods are available)
# ====================================================
# Check
# echo $(check_initial_cluster_helth) => 1 | 0

check_initial_cluster_helth() {
    CLUSTER_NODE_DNS=$(get_healthy_cluster_node_dsn)
    
    CLUSTER_STATE=$(redis-cli -h "$CLUSTER_NODE_DNS" -p 6379 cluster info | awk -F: '/cluster_state/ {print $2}' | tr -d '\r\n' | xargs)
    CLUSTER_NODES=$(redis-cli -h "$CLUSTER_NODE_DNS" -p 6379 cluster info | awk 'NR==6' | cut -d: -f2)
    CLUSTER_MASTERS=$(redis-cli -h "$CLUSTER_NODE_DNS" -p 6379 cluster info | awk 'NR==7' | cut -d: -f2)

    if [ "$CLUSTER_STATE" != "ok" ]; then
        return 0
    elif [ "$CLUSTER_MASTERS" -eq "0" ]; then
        return 0
    elif [ "$CLUSTER_NODES" -eq "0" ]; then
        return 0
    elif [ "$CLUSTER_NODES" -lt "$REPLICAS" ]; then
        return 0
    fi
   

    TOTAL_GROUP_MEMBERS=$(( CLUSTER_REPLICAS + 1 ))
    RATIO=$(( REPLICAS / TOTAL_GROUP_MEMBERS ))
    REVERSE_CHECK=$(( RATIO * TOTAL_GROUP_MEMBERS ))

    if [ "$REPLICAS" -ne "$REVERSE_CHECK" ]; then
        return 0
    else 
        return 1
    fi     
}

slot_distribution_checker() {
    CLUSTER_NODE_DNS=$(get_healthy_cluster_node_dsn)
    SLOTS_NUM=16384

    # IF THE CLUSTER IS IN THE MERGING OR IMPORTING MODE
    if is_cluster_busy; then
        printf "CLUSTER BUSSY \n" >&2
        return 1

    # IF THE CLUSTER IS NOT IN THE MERGING OR IMPORTING MODE
    else

        # CHECK FOR 0 SLOTS MASTER
        SLOTS_0=$(redis-cli --cluster check "$CLUSTER_NODE_DNS:$PORT" | grep 'slots |' | awk -F'|' '{print $2}' | awk '{print $1}' | grep '^0$')

        # IF THERE IS AT LEAST 1 EMPTY MASTER WITH 0 SLOTS
        if [ -n "$SLOTS_0" ]; then

            # GET THE SLOTS WITHOUT 0
            # WE DO THIS BECAUSE A NEW MASTER IS ADDED JUST WITH 0 SLOTS BUT THE CLUSTER IS NOT BUSSY
            # IT MEANS THE REBALANCE IS NOT CALLED YET. THE CLUSTER STILL RECEIVES NODES
            SLOTS=$(redis-cli --cluster check "$CLUSTER_NODE_DNS:$PORT" | grep 'slots |' | awk -F'|' '{print $2}' | awk '{print $1}' | grep -v '^0$')
            
            # GET THE COUNT OF THE NON 0 SLOTS
            SLOTS_COUNT=$(echo "$SLOTS" | wc -l)
        else
             # GET THE SLOT NUMER
            SLOTS=$(redis-cli --cluster check "$CLUSTER_NODE_DNS:$PORT" | grep 'slots |' | awk -F'|' '{print $2}' | awk '{print $1}')

            # GET THE COUNT OF THE NON 0 SLOTS
            SLOTS_COUNT=$(echo "$SLOTS" | wc -l)
        fi

        # IF THE CLUSTER SLOT COUNT IS 0 OR 1 MEANS THE CLUSTER IS NOT READY. WE CAN'T HAVE CLUSTER WITH 1 NODE ONLY
        if [ "$SLOTS_COUNT" -eq 0 ] || [ "$SLOTS_COUNT" -eq 1 ]; then
            print_yellow "CLUSTER NOT READY" 1 >&2
            return 1
        fi

        # GET THE MIN AND MAX SLOT NUMBER DISTRIBUTION ACCROSS THE MASTERS
        # THIS IS PRE CALC FOR CHECKING
        FINAL_DISTRIBUTION_MIN=$((SLOTS_NUM / SLOTS_COUNT))
        FINAL_DISTRIBUTION_MAX=$(math_ceil "$SLOTS_NUM/$SLOTS_COUNT")

        # GET THE MIN MAX SLOT NUMBER DISTRIBUTION IN THE ACTUAL CLUSTER
        # THIS IS WHAT THE CLUSTER HAS NOW
        VALUE_MIN=$(get_min "$SLOTS")
        VALUE_MAX=$(get_max "$SLOTS")

        # IF PRE CALC MIN AND MAX ARE NOT EQUAL TO THE ACTUAL MIN MAX, PROBABLY WE HAVE REDISTRIBUTION
        # NOTE: THE SCRIPT IS BUILT FOR SYMETRIC CLUSTER
        if [ "$FINAL_DISTRIBUTION_MIN" -ne "$VALUE_MIN" ] || [ "$FINAL_DISTRIBUTION_MAX" -ne "$VALUE_MAX" ]; then
            printf "REDISTRIBUTING \n" >&2
            return 1
        
        # THE CLUSTER HAS THE CORRECT DISTRIBUTION AND THERE IS JUST A NEW MASTER/S WITH 0 SLOTS
        # NEXT THE CLUSTER MUST BE REBALANCED
        else
            printf "CLUSTER STABLE \n" >&2
            return 0
        fi        
    fi
}

operation_loop() {
    while true; do
        if slot_distribution_checker; then
            printf "Cluster is stable, exiting loop."
            break
        fi

        printf "Cluster not stable, retrying in 2 seconds..."
        sleep 2
    done
}

# redis-cli --cluster check "redis-node-0.redis-service.authentication.svc.cluster.local:6379" | grep 'slots |' | awk -F'|' '{print $2}' | awk '{print $1}'
# redis-cli --cluster check "redis-node-0.redis-service.authentication.svc.cluster.local:6379"
