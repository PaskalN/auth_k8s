#!/bin/sh

set -e

SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)"

CLI_DIR="$SCRIPT_PATH/cli"

nginx_cluster_preset() {
    "$CLI_DIR"/nginx-cluster/generate_certificate.sh
    "$CLI_DIR"/nginx-cluster/init-script/create_config.sh
}