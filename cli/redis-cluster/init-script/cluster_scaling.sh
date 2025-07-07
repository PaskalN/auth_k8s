#!/bin/sh

# For Debug
# set -x
set -e

add_new_master() {
    operation_loop

    POD_DNS=$(create_pod_dns)
    add_empty_master "$POD_DNS"
}

slave_controller() {
    POD_DNS=$(create_pod_dns)
    IS_LAST_SLAVE=$(is_last_slave "$REDIS_NODE_ID" "$CLUSTER_REPLICAS")

    operation_loop
    add_replica "$POD_DNS"

    if [ "$IS_LAST_SLAVE" -eq 1 ]; then
        print_yellow "This is the LAST SLAVE NODE, running rebalance..." 1            
        
        operation_loop
        call_rebalance
        
    fi
}

init_scale_node() {

    if check_initial_cluster_helth; then
        print_red "CLUSTER IS NOT HEALTY!" 1
        return 1
    fi

    # GET AT LEAST ONE HEALTY CLUSTER NODE DNS
    CLUSTER_NODE_DNS=$(get_healthy_cluster_node_dsn)

    # GET THE POD DNS IF IT IS A PART OF A CLUSTER
    POD_CLUSTER_DNS=$(redis-cli -p "$PORT" cluster nodes | grep myself | awk '{ print $2 }' | cut -d: -f1)

    # IS THIS NODE A PART OF A CLUSTER
    PART_OF_CLUSTER=$([ -n "$POD_CLUSTER_DNS" ] && echo 1 || echo 0)


    if [ "$PART_OF_CLUSTER" -eq "1" ]; then
        print_yellow "This is node is already a part of the cluster masters" 1
        print_green "redis-cli -p ""$PORT"" cluster nodes | grep master" 1

        return 0
    fi

    # CHECKS IF THE NEW CURRENT POD STATUS 0 | 1 - 1 MEANS IT SHOULD BE A MASTER
    IS_MASTER=$(is_master "$REDIS_NODE_ID" "$CLUSTER_REPLICAS")

    # CHECKS IF THE NEW CURRENT POD STATUS 0 | 1 - 1 MEANS IT SHOULD BE A SLAVE
    IS_SLAVE=$(is_slave "$REDIS_NODE_ID" "$CLUSTER_REPLICAS")

    if [ "$IS_MASTER" -eq 1 ]; then
        print_yellow "This is MASTER NODE" 1
        print_yellow "This node will be a part of the cluster as a empty master. The last replica will setup and rebalance the cluter."
        print_yellow "Current master nodes"
        print_green "redis-cli -h ""$CLUSTER_NODE_DNS"" -p ""$PORT"" cluster nodes | grep master" 1

        add_new_master

        print_green "redis-cli -h ""$CLUSTER_NODE_DNS"" -p ""$PORT"" cluster nodes | grep master" 1
    fi

    if [ "$IS_SLAVE" -eq 1 ]; then
        slave_controller
    fi

    return 0
}