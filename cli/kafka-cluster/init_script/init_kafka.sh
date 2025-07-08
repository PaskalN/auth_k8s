#!/bin/sh

set -e

run_kafka() {

    print_green "Starting Kafka server" 1

    if [ -n "$DEBUG" ]; then
        print_green "Settings" 1
        print_yellow "/opt/kafka/bin/kafka-storage.sh format --config ${USER_CONFIG_DIR}/server.properties -cluster-id ${KAFKA_CLUSTER_ID} --initial-controllers ${KAFKA_INITIAL_CONTROLLERS}"
    fi

    if [ ! -f "/var/lib/kafka/data/meta.properties" ]; then
        /opt/kafka/bin/kafka-storage.sh format \
            --config "${USER_CONFIG_DIR}/server.properties" \
            --cluster-id "$KAFKA_CLUSTER_ID" \
            --initial-controllers "$KAFKA_INITIAL_CONTROLLERS"
    fi

    sleep 3

    print_green "Starting Kafka server.properties" 1

    if [ ! -f "${USER_CONFIG_DIR}/server.properties" ]; then
        print_red "ERROR: Kafka config not found at ${USER_CONFIG_DIR}/server.properties" 1
        exit 1
    fi

    exec /opt/kafka/bin/kafka-server-start.sh "${USER_CONFIG_DIR}/server.properties"
}