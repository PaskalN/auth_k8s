#!/bin/sh

set -e

SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)"

HELM_DIR="$SCRIPT_PATH/helm"

. "$SCRIPT_PATH/automate_cli/global_tools.sh"

install_helm_start_point() {
    print_green "Starting Start Point Cluster ..." 1
    HELM_COMMAND="helm upgrade --install start-point $HELM_DIR/start-point/ --values $HELM_DIR/start-point/values.yaml --values $HELM_DIR/start-point/values_mongodb_secrets.yaml"
    
    MAX_ATTEMPTS=5
    ATTEMPT=1
    SUCCESS=false

    until $SUCCESS || [ $ATTEMPT -gt $MAX_ATTEMPTS ]; do
        echo "Attempt $ATTEMPT of $MAX_ATTEMPTS to install Redis..."
        if $HELM_COMMAND; then
            print_green "Start Point Cluster started successfully!"
            SUCCESS=true
        else
            print_yellow "Helm installation failed on attempt $ATTEMPT. Retrying in 5 seconds..."
            ATTEMPT=$((ATTEMPT + 1))
            sleep 5
        fi
    done

    if $SUCCESS; then
        print_green "Start Point Cluster installation completed after $ATTEMPT attempts." 1
    else
        print_red "Start Point Cluster installation failed after $MAX_ATTEMPTS attempts. Please check logs for errors." 1
        exit 1
    fi
}

uninstall_helm_start_point() {
    print_yellow "Stoping Redis Cluster ..." 1
    HELM_COMMAND="helm uninstall start-point"
    
    MAX_ATTEMPTS=5
    ATTEMPT=1
    SUCCESS=false

    until $SUCCESS || [ $ATTEMPT -gt $MAX_ATTEMPTS ]; do
        echo "Attempt $ATTEMPT of $MAX_ATTEMPTS to uninstall Start Point Cluster..."
        if $HELM_COMMAND; then
            print_green "Start Point Cluster Cluster stopped successfully!"
            SUCCESS=true
        else
            print_yellow "Helm uninstall failed on attempt $ATTEMPT. Retrying in 5 seconds..."
            ATTEMPT=$((ATTEMPT + 1))
            sleep 5
        fi
    done

    if $SUCCESS; then
        print_green "Start Point Cluster uninstall completed after $ATTEMPT attempts." 1
    else
        print_red "Start Point Cluster uninstall failed after $MAX_ATTEMPTS attempts. Please check logs for errors." 1
        exit 1
    fi
}
