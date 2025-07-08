#!/bin/sh

set -e

generate_controller_server_file() {
    if [ "$KAFKA_PROCESS_ROLES" = "controller" ]; then
        sed -e "s#((KAFKA_NODE_ID))#$KAFKA_NODE_ID#g" \
            -e "s#((KAFKA_LOG_DIR))#$KAFKA_LOG_DIR#g" \
            -e "s#((KAFKA_LISTENERS))#$KAFKA_LISTENERS#g" \
            -e "s#((KAFKA_PROCESS_ROLES))#$KAFKA_PROCESS_ROLES#g" \
            -e "s#((KAFKA_CONTROLLER_LISTENER_NAMES))#$KAFKA_CONTROLLER_LISTENER_NAMES#g" \
            -e "s#((KAFKA_CLUSTER_ID))#$KAFKA_CLUSTER_ID#g" \
            -e "s#((KAFKA_CONTROLLER_QUORUM_VOTERS))#$KAFKA_CONTROLLER_QUORUM_VOTERS#g" \
            -e "s#((KAFKA_ADVERTISED_LISTENERS))#$KAFKA_ADVERTISED_LISTENERS#g" \
            -e "s#((KAFKA_CONTROLLER_QUORUM_BOOTSTRAP_SERVERS))#$KAFKA_CONTROLLER_QUORUM_BOOTSTRAP_SERVERS#g" \
            "$USER_CONFIG_DIR/commando/controller.properties" \
            > "$USER_CONFIG_DIR/server.properties"
    fi
}