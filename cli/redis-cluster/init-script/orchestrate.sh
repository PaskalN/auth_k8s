#!/bin/sh

set -e

# Returns the node number in the cluster
# The method will return the total number only for a member in the cluster
# ========================================================================
# Check
# echo $(get_total_nodes "$PORT")
# => 6

get_total_nodes() {
    PORT=$1
    total=$(redis-cli -p "$PORT" cluster nodes | wc -l)
    echo "$total"
}

# Returns the pod dns set
# depends from the REPLICAS parameter
# ===============================
# Check
# echo $(construct_initial_node_set "6" "service_name" "namespace" "pod_name")
# => pod_name-0.service_name.namespace.svc.cluster.local ... pod_name-5.service_name.namespace.svc.cluster.local

construct_initial_node_set() {
    REPLICAS=$1
    SERVICE_NAME=$2
    NAMESPACE=$3
    POD_NAME=$4

    result=$(
        awk -v replicas="$REPLICAS" -v service_name="$SERVICE_NAME" -v namespace="$NAMESPACE" -v pod_name="$POD_NAME" '
            BEGIN {
                sep = ""

                for (i = 0; i < replicas; i++) {
                    printf("%s%s-%d.%s.%s.svc.cluster.local", sep, pod_name, i, service_name, namespace)
                    sep = " "
                }
            }
        '
    )

    echo "$result"
}

# Returns the pod dns set with port at the end
# depends from the REPLICAS parameter
# ====================================================
# Check
# echo $(construct_initial_node_set_port "6" "service_name" "namespace" "pod_name" "6373")
# => pod_name-0.service_name.namespace.svc.cluster.local:6373 ... pod_name-5.service_name.namespace.svc.cluster.local:6373

construct_initial_node_set_port() {
    REPLICAS=$1
    SERVICE_NAME=$2
    NAMESPACE=$3
    POD_NAME=$4
    PORT=$5

    result=$(
        awk -v replicas="$REPLICAS" -v service_name="$SERVICE_NAME" -v namespace="$NAMESPACE" -v pod_name="$POD_NAME" -v port="$PORT" '
            BEGIN {
                sep = ""

                for (i = 0; i < replicas; i++) {
                    printf("%s%s-%d.%s.%s.svc.cluster.local:%s", sep, pod_name, i, service_name, namespace, port)
                    sep = " "
                }
            }
        '
    )


    echo "$result"
}

construct_all_node_set() {
    REPLICAS=$1
    SERVICE_NAME=$2
    NAMESPACE=$3
    POD_NAME=$4

    total=$(get_total_nodes "$PORT")

    result=$(
        awk -v total="$REPLICAS" -v service_name="$SERVICE_NAME" -v namespace="$NAMESPACE" -v pod_name="$POD_NAME" '
            BEGIN {
                sep = ""

                for (i = 0; i < total; i++) {
                    printf("%s%s-%d.%s.%s.svc.cluster.local", sep, pod_name, i, service_name, namespace)
                    sep = " "
                }
            }
        '
    )

    echo "$result"
}

construct_all_node_set_port() {
    REPLICAS=$1
    SERVICE_NAME=$2
    NAMESPACE=$3
    POD_NAME=$4
    PORT=$5

    total=$(get_total_nodes "$PORT")

    result=$(
        awk -v total="$REPLICAS" -v service_name="$SERVICE_NAME" -v namespace="$NAMESPACE" -v pod_name="$POD_NAME" -v port="$PORT" '
            BEGIN {
                sep = ""

                for (i = 0; i < total; i++) {
                    printf("%s%s-%d.%s.%s.svc.cluster.local:%s", sep, pod_name, i, service_name, namespace, port)
                    sep = " "
                }
            }
        '
    )

    echo "$result"
}

construct_node_set() {
    GROUP_SET=$1
    SERVICE_NAME=$2
    NAMESPACE=$3
    POD_NAME=$4

    GROUP_SET_TRIM=$(echo "$GROUP_SET" | tr ',' ' ')

    result=$(
        echo "$GROUP_SET_TRIM" | awk -v service_name="$SERVICE_NAME" -v namespace="$NAMESPACE" -v pod_name="$POD_NAME" '
            {
                sep = ""
                for (i = 1; i <= NF; i++) {
                    pod_n = $i - 1
                    printf("%s%s-%s.%s.%s.svc.cluster.local", sep, pod_name, pod_n, service_name, namespace)
                    sep = " "
                }
            }
        '
    )

    echo "$result"
}

construct_node_set_port() {
    GROUP_SET=$1
    SERVICE_NAME=$2
    NAMESPACE=$3
    POD_NAME=$4
    PORT=$5

    GROUP_SET_TRIM=$(echo "$GROUP_SET" | tr ',' ' ')

    result=$(
        echo "$GROUP_SET_TRIM" | awk -v service_name="$SERVICE_NAME" -v namespace="$NAMESPACE" -v pod_name="$POD_NAME" -v port="$PORT" '
            {
                sep = ""
                for (i = 1; i <= NF; i++) {
                    pod_n = $i - 1
                    printf("%s%s-%s.%s.%s.svc.cluster.local:%s", sep, pod_name, pod_n, service_name, namespace, port)
                    sep = " "
                }
            }
        '
    )

    echo "$result"
}

# Returns the current pod k8s service DNS
# ====================================================
# Check
# echo $(create_pod_dns)
# => redis-node-0.redis-service.authentication.svc.cluster.local:6379
create_pod_dns() {
    POD_N=$((REDIS_NODE_ID - 1))
    echo "${POD_NAME}-${POD_N}.${SERVICE_NAME}.${NAMESPACE}.svc.cluster.local:${PORT}"
}

# Returns the pod k8s service DNS based on the given replica number
# Rememeber: POD Numbers start from 0. Redis nodes start from 1
# ====================================================
# Check
# echo $(create_any_pod_dns "5")
# => redis-node-4.redis-service.authentication.svc.cluster.local:6379
create_any_pod_dns() {
    REDIS_NODE_ID="$1"
    POD_N=$((REDIS_NODE_ID - 1))
    echo "${POD_NAME}-${POD_N}.${SERVICE_NAME}.${NAMESPACE}.svc.cluster.local:${PORT}"
}


# Returns the count of pods based on given replicas number
# ====================================================
# Check
# echo $(get_master_set_replicas "5")
# => 6
get_master_set_replicas() {
    r=$(math_floor "$1")
    echo $((r + 1))
}


# Returns the position in the pod group
# ====================================================
# Check
# echo $(get_delta "1" "3") => 1 - set starts
# echo $(get_delta "2" "3") => 2
# echo $(get_delta "3" "3") => 3
# echo $(get_delta "4" "3") => 4 - set ends
# echo $(get_delta "5" "3") => 1 - new set start

get_delta() {
    node_num=$1
    slaves=$2

    pod_num=$((node_num - 1))

    master_set=$(get_master_set_replicas "$slaves") # 1 master 1 slave = 2

    if [ "$node_num" -eq 1 ]; then
        div=0
    else
        div=$(( pod_num / master_set ))
    fi

    delta=$(( node_num - ( master_set * div) ))

    echo "$delta"
}

# Returns the group master number
# 
# If we have a group of nodes in the cluster: let say 1m 4f and if 
# we pass of the pod nums we will recieve the the master number in the group
# ====================================================
# If we have number 11 of the node and 4 replicas it means that we have 5 nodes in the group (1m + 4f)
# If number 6 is the master node it means that the next master is 11 -> 6 + 5 = 11
# 
# Check
# echo $(get_master_n "2" "1") => 6

# echo $(get_master_n "10" "4") => 6
# echo $(get_master_n "11" "4") => 11
# echo $(get_master_n "12" "4") => 11
# echo $(get_master_n "13" "4") => 11
# echo $(get_master_n "14" "4") => 11
# echo $(get_master_n "15" "4") => 11
# echo $(get_master_n "16" "4") => 16

get_master_n() {
    node_num=$1
    slaves=$2 # Indicates how many replicas the master has

    delta=$(get_delta "$node_num" "$slaves")
    echo $((node_num - delta + 1))
}

# Returns the last memeber (f) in the group
# 
# Similar to the get_master_n but returns the last number not the first one
# ====================================================
# echo $(get_last_slave_n "10" "4") => 10
# echo $(get_last_slave_n "11" "4") => 15
# echo $(get_last_slave_n "12" "4") => 15
# echo $(get_last_slave_n "13" "4") => 15
# echo $(get_last_slave_n "14" "4") => 15
# echo $(get_last_slave_n "15" "4") => 15
# echo $(get_last_slave_n "16" "4") => 20
get_last_slave_n() {
    pod_num=$1
    slaves=$2

    master_set=$(get_master_set_replicas "$slaves")
    delta=$(get_delta "$pod_num" "$slaves")
    div=$((master_set - delta))

    echo $((pod_num + div))
}

# Returns all the pod numbers in the group
# ====================================================
# echo $(group_pods "1" "4") => 1,2,3,4,5
# echo $(group_pods "10" "4") => 6,7,8,9,10
# echo $(group_pods "11" "4") => 11,12,13,14,15
# echo $(group_pods "16" "4") => 16,17,18,19,20
group_pods() {
    node_num=$1
    slaves=$2
    master_n=$(get_master_n "$node_num" "$slaves")

    result=$(
    awk -v master_n="$master_n" -v slaves="$slaves" '
        BEGIN {
            sep = ""
            end = master_n + slaves + 1

            for (i = master_n; i < end; i++) {
                printf("%s%d", sep, i)
                sep = ","
            }
        }
    '
    )

    echo "$result"
}

# echo $(group_pods "$node_num" "$slaves")
# echo $(get_master_n "$node_num" "$slaves")

# Returns 0 | 1. Indicates is the given pod number a master
# ====================================================
# echo $(is_master "1" "4") => 1 - yes
# echo $(is_master "10" "4") => 0 - no
is_master() {
    node_num=$1
    slaves=$2

    delta=$(get_delta "$node_num" "$slaves")
    if [ "$delta" -eq 1 ]; then
        echo "1"
    else
        echo "0"
    fi
}

# Returns 0 | 1. Indicates is the given node number a slave
# ====================================================
# echo $(is_slave "1" "4") => 0 - no
# echo $(is_slave "10" "4") => 1 - yes
is_slave() {
    node_num=$1
    slaves=$2

    delta=$(get_delta "$node_num" "$slaves")
    if [ "$delta" -eq 1 ]; then
        echo "0"
    else
        echo "1"
    fi
}

# Returns 0 | 1. Indicates is the given node number the last slave
# ====================================================
# Check
# echo $(is_last_slave "1" "3") => 0 - set starts NO
# echo $(is_last_slave "2" "3") => 0 - NO
# echo $(is_last_slave "3" "3") => 0 - NO
# echo $(is_last_slave "4" "3") => 1 - set ends YES
# echo $(is_last_slave "5" "3") => 0 - new set start NO
is_last_slave() {
    node_num=$1
    slaves=$2
    master_set=$(get_master_set_replicas "$slaves")

    delta=$(get_delta "$node_num" "$slaves")
    if [ "$delta" -eq "$master_set" ]; then
        echo "1"
    else
        echo "0"
    fi
}

