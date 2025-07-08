#!/bin/sh

set -e

cd "$(dirname "$0")"

SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)"

HELM_DIR="$SCRIPT_PATH/helm"

. "$SCRIPT_PATH/automate_cli/global_tools.sh"

install_helm_mongodb() {
    print_green "Starting MongoDB Cluster ..." 1
    HELM_COMMAND="helm install mongo-cluster $HELM_DIR/mongodb-cluster/ --values $HELM_DIR/mongodb-cluster/values.yaml --values $HELM_DIR/mongodb-cluster/values_secrets.yaml"
    
    MAX_ATTEMPTS=5
    ATTEMPT=1
    SUCCESS=false

    until $SUCCESS || [ $ATTEMPT -gt $MAX_ATTEMPTS ]; do
        echo "Attempt $ATTEMPT of $MAX_ATTEMPTS to install MongoDB..."
        if $HELM_COMMAND; then
            print_green "MongoDB Cluster started successfully!"
            SUCCESS=true
        else
            print_yellow "Helm installation failed on attempt $ATTEMPT. Retrying in 5 seconds..."
            ATTEMPT=$((ATTEMPT + 1))
            sleep 5
        fi
    done

    if $SUCCESS; then
        print_green "MongoDB Cluster installation completed after $ATTEMPT attempts." 1
    else
        print_red "MongoDB Cluster installation failed after $MAX_ATTEMPTS attempts. Please check logs for errors." 1
        exit 1
    fi
}

uninstall_helm_mongodb() {
    print_yellow "Stoping MongoDB Cluster ..." 1
    HELM_COMMAND="helm uninstall mongo-cluster"
    
    MAX_ATTEMPTS=5
    ATTEMPT=1
    SUCCESS=false

    until $SUCCESS || [ $ATTEMPT -gt $MAX_ATTEMPTS ]; do
        echo "Attempt $ATTEMPT of $MAX_ATTEMPTS to uninstall MongoDB Cluster..."
        if $HELM_COMMAND; then
            print_green "MongoDB Cluster Cluster stopped successfully!"
            SUCCESS=true
        else
            print_yellow "Helm uninstall failed on attempt $ATTEMPT. Retrying in 5 seconds..."
            ATTEMPT=$((ATTEMPT + 1))
            sleep 5
        fi
    done

    if $SUCCESS; then
        print_green "MongoDB Cluster uninstall completed after $ATTEMPT attempts." 1
    else
        print_red "MongoDB Cluster uninstall failed after $MAX_ATTEMPTS attempts. Please check logs for errors." 1
        exit 1
    fi
}
