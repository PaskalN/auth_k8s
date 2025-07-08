#!/bin/sh

set -e

SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)"

HELM_DIR="$SCRIPT_PATH/helm"

. "$SCRIPT_PATH/automate_cli/global_tools.sh"

install_helm_kafka_controller() {
    print_green "Starting Kafka Controller Cluster ..." 1
    HELM_COMMAND="helm install kafka-controller $HELM_DIR/kafka-controller/ --values $HELM_DIR/kafka-controller/values.yaml --values $HELM_DIR/kafka-controller/values_uuids.yaml"
    
    MAX_ATTEMPTS=5
    ATTEMPT=1
    SUCCESS=false

    until $SUCCESS || [ $ATTEMPT -gt $MAX_ATTEMPTS ]; do
        echo "Attempt $ATTEMPT of $MAX_ATTEMPTS to install Kafka Controller..."
        if $HELM_COMMAND; then
            print_green "Kafka Controller Cluster started successfully!"
            SUCCESS=true
        else
            print_yellow "Helm installation failed on attempt $ATTEMPT. Retrying in 5 seconds..."
            ATTEMPT=$((ATTEMPT + 1))
            sleep 5
        fi
    done

    if $SUCCESS; then
        print_green "Kafka Controller installation completed after $ATTEMPT attempts." 1
    else
        print_red "Kafka Controller installation failed after $MAX_ATTEMPTS attempts. Please check logs for errors." 1
        exit 1
    fi
}

uninstall_helm_kafka_controller() {
    print_yellow "Stoping Kafka Controller Cluster ..." 1
    HELM_COMMAND="helm uninstall kafka-controller"
    
    MAX_ATTEMPTS=5
    ATTEMPT=1
    SUCCESS=false

    until $SUCCESS || [ $ATTEMPT -gt $MAX_ATTEMPTS ]; do
        echo "Attempt $ATTEMPT of $MAX_ATTEMPTS to uninstall Kafka Controller..."
        if $HELM_COMMAND; then
            print_green "Kafka Controller Cluster stopped successfully!"
            SUCCESS=true
        else
            print_yellow "Helm uninstall failed on attempt $ATTEMPT. Retrying in 5 seconds..."
            ATTEMPT=$((ATTEMPT + 1))
            sleep 5
        fi
    done

    if $SUCCESS; then
        print_green "Kafka Controller uninstall completed after $ATTEMPT attempts." 1
    else
        print_red "Kafka Controller uninstall failed after $MAX_ATTEMPTS attempts. Please check logs for errors." 1
        exit 1
    fi
}


install_helm_kafka_broker() {
    print_green "Starting Kafka Broker Cluster ..." 1
    HELM_COMMAND="helm install kafka-broker $HELM_DIR/kafka-broker/ --values $HELM_DIR/kafka-broker/values.yaml --values $HELM_DIR/kafka-broker/values_uuids.yaml"
    
    MAX_ATTEMPTS=5
    ATTEMPT=1
    SUCCESS=false

    until $SUCCESS || [ $ATTEMPT -gt $MAX_ATTEMPTS ]; do
        echo "Attempt $ATTEMPT of $MAX_ATTEMPTS to install Kafka Broker..."
        if $HELM_COMMAND; then
            print_green "Kafka Broker Cluster started successfully!"
            SUCCESS=true
        else
            print_yellow "Helm installation failed on attempt $ATTEMPT. Retrying in 5 seconds..."
            ATTEMPT=$((ATTEMPT + 1))
            sleep 5
        fi
    done

    if $SUCCESS; then
        print_green "Kafka Broker installation completed after $ATTEMPT attempts." 1
    else
        print_red "Kafka Broker installation failed after $MAX_ATTEMPTS attempts. Please check logs for errors." 1
        exit 1
    fi
}

uninstall_helm_kafka_broker() {
    print_yellow "Stoping Kafka Broker Cluster ..." 1
    HELM_COMMAND="helm uninstall kafka-broker"
    
    MAX_ATTEMPTS=5
    ATTEMPT=1
    SUCCESS=false

    until $SUCCESS || [ $ATTEMPT -gt $MAX_ATTEMPTS ]; do
        echo "Attempt $ATTEMPT of $MAX_ATTEMPTS to uninstall Kafka Broker..."
        if $HELM_COMMAND; then
            print_green "Kafka Broker Cluster stopped successfully!"
            SUCCESS=true
        else
            print_yellow "Helm uninstall failed on attempt $ATTEMPT. Retrying in 5 seconds..."
            ATTEMPT=$((ATTEMPT + 1))
            sleep 5
        fi
    done

    if $SUCCESS; then
        print_green "Kafka Broker uninstall completed after $ATTEMPT attempts." 1
    else
        print_red "Kafka Broker uninstall failed after $MAX_ATTEMPTS attempts. Please check logs for errors." 1
        exit 1
    fi
}
