#!/bin/sh

set -e

cd "$(dirname "$0")"

SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)"

. "$SCRIPT_PATH/automate_cli/global_tools.sh"

HELM_DIR="$SCRIPT_PATH/helm"

install_helm_nginx_cluster() {
    print_green "Starting Nginx Cluster ..." 1
    HELM_COMMAND="helm upgrade --install nginx-cluster $HELM_DIR/nginx-cluster/ --values $HELM_DIR/nginx-cluster/values.yaml"
    
    MAX_ATTEMPTS=5
    ATTEMPT=1
    SUCCESS=false

    until $SUCCESS || [ $ATTEMPT -gt $MAX_ATTEMPTS ]; do
        echo "Attempt $ATTEMPT of $MAX_ATTEMPTS to install MongoDB..."
        if $HELM_COMMAND; then
            print_green "Nginx Cluster started successfully!"
            SUCCESS=true
        else
            print_yellow "Helm installation failed on attempt $ATTEMPT. Retrying in 5 seconds..."
            ATTEMPT=$((ATTEMPT + 1))
            sleep 5
        fi
    done

    if $SUCCESS; then
        print_green "Nginx Cluster installation completed after $ATTEMPT attempts." 1
    else
        print_red "Nginx Cluster installation failed after $MAX_ATTEMPTS attempts. Please check logs for errors." 1
        exit 1
    fi
}

uninstall_helm_nginx_cluster() {
    print_yellow "Stoping Nginx Cluster ..." 1
    HELM_COMMAND="helm uninstall nginx-cluster"
    
    MAX_ATTEMPTS=5
    ATTEMPT=1
    SUCCESS=false

    until $SUCCESS || [ $ATTEMPT -gt $MAX_ATTEMPTS ]; do
        echo "Attempt $ATTEMPT of $MAX_ATTEMPTS to uninstall Nginx Cluster..."
        if $HELM_COMMAND; then
            print_green "Nginx Cluster Cluster stopped successfully!"
            SUCCESS=true
        else
            print_yellow "Helm uninstall failed on attempt $ATTEMPT. Retrying in 5 seconds..."
            ATTEMPT=$((ATTEMPT + 1))
            sleep 5
        fi
    done

    if $SUCCESS; then
        print_green "Nginx Cluster uninstall completed after $ATTEMPT attempts." 1
    else
        print_red "Nginx Cluster uninstall failed after $MAX_ATTEMPTS attempts. Please check logs for errors." 1
        exit 1
    fi
}
