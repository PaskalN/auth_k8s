#!/bin/sh

set -e

SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)"

CLI_DIR="$SCRIPT_PATH/cli"

redis_preset() {
    "$CLI_DIR"/redis-cluster/generate_certificate.sh
    "$CLI_DIR"/redis-cluster/init-script/create-config.sh
}