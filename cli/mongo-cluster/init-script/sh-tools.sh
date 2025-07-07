#!/bin/bash

set -e

# Green Printer
# =============
print_green() {
    TEXT=$1
    BORDER=${2:-0}

    if [ "$BORDER" -eq 1 ]; then
        printf "\n" 
        printf "\033[0;32m %s \033[0m" "=====================================" 
        printf "\n" 
        printf "\033[0;32m %s \033[0m" "$TEXT" 
        printf "\n" 
        printf "\033[0;32m %s \033[0m" "=====================================" 
        printf "\n" 
    else
        printf "\n" 
        printf "\033[0;32m %s \033[0m" "$TEXT" 
        printf "\n" 
    fi
}

# Yellow Printer
# =============
print_yellow() {
    TEXT=$1
    BORDER=${2:-0}

    if [ "$BORDER" -eq 1 ]; then
        printf "\n" 
        printf "\033[0;33m %s \033[0m" "=====================================" 
        printf "\n" 
        printf "\033[0;33m %s \033[0m" "$TEXT" 
        printf "\n" 
        printf "\033[0;33m %s \033[0m" "=====================================" 
        printf "\n" 
    else
        printf "\n" 
        printf "\033[0;33m %s \033[0m" "$TEXT" 
        printf "\n" 
    fi
}

# Red Printer
# =============
print_red() {
    TEXT=$1
    BORDER=${2:-0}

    if [ "$BORDER" -eq 1 ]; then
        printf "\n" 
        printf "\033[0;31m %s \033[0m" "=====================================" 
        printf "\n" 
        printf "\033[0;31m %s \033[0m" "$TEXT" 
        printf "\n" 
        printf "\033[0;31m %s \033[0m" "=====================================" 
        printf "\n" 
    else
        printf "\n" 
        printf "\033[0;31m %s \033[0m" "$TEXT" 
        printf "\n" 
    fi
}

detect_primary_host() {
    CONN_DNS=$(get_connection_dns_set)

    until mongosh "$CONN_DNS" --eval "db.adminCommand('ping')" >/dev/null 2>&1; do
        print_yellow "Waiting for MongoDB to be ready..." 1
        sleep 5;
    done

    PRIMARY_HOST=$(mongosh "$CONN_DNS" --eval 'rs.isMaster().primary')
    echo "$PRIMARY_HOST"
}

get_connection_dns_set() {
    index="0"
    DNS_SET=""
    SEP=""

    while [ "$index" -lt "$REPLICAS" ]; do
        DNS_SET="${DNS_SET}${SEP}${POD_NAME}-${index}.${SERVICE_NAME}.${NAMESPACE}.svc.cluster.local:${PORT}"
        index=$((index + 1))
        SEP=","
    done

    CONN_DNS="mongodb://${CLEAN_USER}:${CLEAN_PASS}@${DNS_SET}/admin?replicaSet=${CLUSTER_ID}"

    echo "$CONN_DNS"
}

get_cluster_dns_set() {
    CONN_DNS=$(get_connection_dns_set)
    CLUSTER_DNS=$(mongosh "$CONN_DNS" --quiet --eval "rs.status().members.map(m => m.name.split(':')[0]).join('\n')")

    echo "$CLUSTER_DNS"
}

get_initial_dns_set() {
    index="0"
    DNS_SET=""
    SEP=""

    while [ "$index" -lt "$REPLICAS" ]; do
        DNS_SET="${DNS_SET}${SEP}${POD_NAME}-${index}.${SERVICE_NAME}.${NAMESPACE}.svc.cluster.local:${PORT}"
        index=$((index + 1))
        SEP=" "
    done

    echo "$DNS_SET" 
}