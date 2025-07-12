#!/bin/sh

set -e

SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)"

CLI_DIR="$SCRIPT_PATH/cli"

localhost_preset() {
    "$CLI_DIR"/localhost-nginx/generate_certificate.sh
    "$CLI_DIR"/localhost-nginx/init-script/create_config.sh
}