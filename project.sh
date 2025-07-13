#!/bin/sh

set -e

# Default values
CLUSTER=""
ACTION=""
PRESET=""

CLUSTER_DIR="./automate_cli/clusters"
PRESET_DIR="./automate_cli/preset"
. "$CLUSTER_DIR/localhost_nginx.sh"
. "$CLUSTER_DIR/nginx_cluster.sh"
. "$CLUSTER_DIR/start_point.sh"

. "$PRESET_DIR/localhost_nginx.sh"
. "$PRESET_DIR/nginx_cluster.sh"

# Parse args
while [ "$#" -gt 0 ]; do
  case "$1" in
    --cluster)
      CLUSTER="$2"
      shift 2
      ;;
    --action)
      ACTION="$2"
      shift 2
      ;;
    --preset)
      PRESET="$2"
      shift 2
      ;;    
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

nginx_cluster_up() {
    install_helm_nginx_cluster
}

nginx_cluster_down() {
    uninstall_helm_nginx_cluster
}

localhost_up() {
    install_helm_localhost
}

localhost_down() {
    uninstall_helm_localhost
}

start_point_up() {
    install_helm_start_point
}

start_point_down() {
    uninstall_helm_start_point
}

if [ "$CLUSTER" = "all" ]; then
    if [ "$ACTION" = "start" ]; then

        if [ -n "$PRESET" ]; then
            print_yellow "Generating cluster presets..." 1
            localhost_preset
            nginx_cluster_preset
            print_yellow "Cluster presets generated" 1
        fi

        localhost_up
        nginx_cluster_up
        start_point_up
    fi

    if [ "$ACTION" = "stop" ]; then
        localhost_down
        nginx_cluster_down
        start_point_down
    fi
else
    for service in $(echo "$CLUSTER" | tr ',' ' '); do        
        if [ "$ACTION" = "start" ]; then            
            if [ "$service" = "localhost" ]; then
                if [ "$PRESET" = "true" ]; then
                    print_yellow "Generating Localhost presets..." 1
                    localhost_preset
                    print_yellow "Localhost presets generated" 1
                fi
                localhost_up
            fi

            if [ "$service" = "nginx" ]; then
                if [ "$PRESET" = "true" ]; then
                    print_yellow "Generating Nginx presets..." 1
                    nginx_cluster_preset
                    print_yellow "Nginx presets generated" 1
                fi
                nginx_cluster_up
            fi

            if [ "$service" = "start-point" ]; then               
                start_point_up
            fi
        fi

        if [ "$ACTION" = "stop" ]; then
            if [ "$service" = "localhost" ]; then
                localhost_down
            fi

            if [ "$service" = "nginx" ]; then
                nginx_cluster_down
            fi

            if [ "$service" = "start-point" ]; then
                start_point_down
            fi
        fi
    done
fi
