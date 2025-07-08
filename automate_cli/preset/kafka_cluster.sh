#!/bin/sh

set -e

SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)"

CLI_DIR="$SCRIPT_PATH/cli"

kafka_preset() {
    "$CLI_DIR"/kafka-cluster/init_script/generate_uuid_values.sh
    "$CLI_DIR"/kafka-cluster/init_script/create_config.sh
}