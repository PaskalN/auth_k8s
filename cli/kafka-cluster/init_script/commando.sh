#!/bin/sh

set -e

if [ -z "$USER_CONFIG_DIR" ]; then
    print_red "USER_CONFIG_DIR is not defined" 1
    exit 1
fi

. "${USER_CONFIG_DIR}/commando/include.sh"

environment_checker

generate_controller_server_file

generate_broker_server_file

debug

run_kafka