#!/bin/sh

set -e

SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)"

HELM_DIR="$SCRIPT_PATH/helm"

. "$SCRIPT_PATH/automate_cli/global_tools.sh"

install_helm_redis() {
    print_green "Starting Redis Cluster ..." 1
    HELM_COMMAND="helm upgrade --install redis-cluster $HELM_DIR/redis-cluster/ --values $HELM_DIR/redis-cluster/values.yaml --values $HELM_DIR/redis-cluster/values_secrets.yaml"
    
    MAX_ATTEMPTS=5
    ATTEMPT=1
    SUCCESS=false

    until $SUCCESS || [ $ATTEMPT -gt $MAX_ATTEMPTS ]; do
        echo "Attempt $ATTEMPT of $MAX_ATTEMPTS to install Redis..."
        if $HELM_COMMAND; then
            print_green "Redis Cluster started successfully!"
            SUCCESS=true
        else
            print_yellow "Helm installation failed on attempt $ATTEMPT. Retrying in 5 seconds..."
            ATTEMPT=$((ATTEMPT + 1))
            sleep 5
        fi
    done

    if $SUCCESS; then
        print_green "Redis Cluster installation completed after $ATTEMPT attempts." 1
    else
        print_red "Redis Cluster installation failed after $MAX_ATTEMPTS attempts. Please check logs for errors." 1
        exit 1
    fi
}

uninstall_helm_redis() {
    print_yellow "Stoping Redis Cluster ..." 1
    HELM_COMMAND="helm uninstall redis-cluster"
    
    MAX_ATTEMPTS=5
    ATTEMPT=1
    SUCCESS=false

    until $SUCCESS || [ $ATTEMPT -gt $MAX_ATTEMPTS ]; do
        echo "Attempt $ATTEMPT of $MAX_ATTEMPTS to uninstall Redis Cluster..."
        if $HELM_COMMAND; then
            print_green "Redis Cluster Cluster stopped successfully!"
            SUCCESS=true
        else
            print_yellow "Helm uninstall failed on attempt $ATTEMPT. Retrying in 5 seconds..."
            ATTEMPT=$((ATTEMPT + 1))
            sleep 5
        fi
    done

    if $SUCCESS; then
        print_green "Redis Cluster uninstall completed after $ATTEMPT attempts." 1
    else
        print_red "Redis Cluster uninstall failed after $MAX_ATTEMPTS attempts. Please check logs for errors." 1
        exit 1
    fi
}
