#!/bin/sh

set -e

. "${USER_CONFIG_DIR}/commando/global_tools.sh"

if [ "$KAFKA_PROCESS_ROLES" = "controller" ]; then
    . "${USER_CONFIG_DIR}/commando/commando_controller_members.sh"
fi

if [ "$KAFKA_PROCESS_ROLES" = "broker" ]; then
    . "${USER_CONFIG_DIR}/commando/commando_broker_members.sh"
fi

. "${USER_CONFIG_DIR}/commando/environment_checker.sh"

. "${USER_CONFIG_DIR}/commando/default_values.sh"

. "${USER_CONFIG_DIR}/commando/init_kafka.sh"

. "${USER_CONFIG_DIR}/commando/controller_server_properties.sh"

. "${USER_CONFIG_DIR}/commando/broker_server_properties.sh"

. "${USER_CONFIG_DIR}/commando/debug.sh"