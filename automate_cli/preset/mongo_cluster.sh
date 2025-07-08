#!/bin/sh

set -e

SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)"

CLI_DIR="$SCRIPT_PATH/cli"

mongodb_preset() {
    "$CLI_DIR"/mongo-cluster/generate_keyfiles.sh
    "$CLI_DIR"/mongo-cluster/init-script/create-config.sh
}