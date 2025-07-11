#!/bin/sh

set -e

cd "$(dirname "$0")"

SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)"

. "$SCRIPT_PATH/automate_cli/global_tools.sh"

HELM_DIR="$SCRIPT_PATH/helm"

install_helm_localhost() {
    print_green "Starting Localhost Nginx ..." 1
    HELM_COMMAND="helm upgrade --install localhost-nginx $HELM_DIR/localhost-nginx/ --values $HELM_DIR/localhost-nginx/values.yaml"
    
    MAX_ATTEMPTS=5
    ATTEMPT=1
    SUCCESS=false

    until $SUCCESS || [ $ATTEMPT -gt $MAX_ATTEMPTS ]; do
        echo "Attempt $ATTEMPT of $MAX_ATTEMPTS to install MongoDB..."
        if $HELM_COMMAND; then
            print_green "Localhost Nginx started successfully!"
            SUCCESS=true
        else
            print_yellow "Helm installation failed on attempt $ATTEMPT. Retrying in 5 seconds..."
            ATTEMPT=$((ATTEMPT + 1))
            sleep 5
        fi
    done

    if $SUCCESS; then
        print_green "Localhost Nginx installation completed after $ATTEMPT attempts." 1
    else
        print_red "Localhost Nginx installation failed after $MAX_ATTEMPTS attempts. Please check logs for errors." 1
        exit 1
    fi
}

uninstall_helm_localhost() {
    print_yellow "Stoping Localhost Nginx ..." 1
    HELM_COMMAND="helm uninstall localhost-nginx"
    
    MAX_ATTEMPTS=5
    ATTEMPT=1
    SUCCESS=false

    until $SUCCESS || [ $ATTEMPT -gt $MAX_ATTEMPTS ]; do
        echo "Attempt $ATTEMPT of $MAX_ATTEMPTS to uninstall Localhost Nginx..."
        if $HELM_COMMAND; then
            print_green "Localhost Nginx Cluster stopped successfully!"
            SUCCESS=true
        else
            print_yellow "Helm uninstall failed on attempt $ATTEMPT. Retrying in 5 seconds..."
            ATTEMPT=$((ATTEMPT + 1))
            sleep 5
        fi
    done

    if $SUCCESS; then
        print_green "Localhost Nginx uninstall completed after $ATTEMPT attempts." 1
    else
        print_red "Localhost Nginx uninstall failed after $MAX_ATTEMPTS attempts. Please check logs for errors." 1
        exit 1
    fi
}
