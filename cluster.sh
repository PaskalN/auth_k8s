#!/bin/sh

set -e

# Default values
CLUSTER=""
ACTION=""
PRESET=""

CLUSTER_DIR="./automate_cli/clusters"
PRESET_DIR="./automate_cli/preset"
. "$CLUSTER_DIR/kafka_cluster.sh"
. "$CLUSTER_DIR/mongo_cluster.sh"
. "$CLUSTER_DIR/redis_cluster.sh"
. "$CLUSTER_DIR/localhost_nginx.sh"
. "$CLUSTER_DIR/nginx_cluster.sh"

. "$PRESET_DIR/kafka_cluster.sh"
. "$PRESET_DIR/mongo_cluster.sh"
. "$PRESET_DIR/redis_cluster.sh"
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
    --help)
      echo "Usage: $0 --something <value> --foo <value>"
      exit 0
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

kafka_up() {
    install_helm_kafka_controller
    install_helm_kafka_broker
}

kafka_down() {
    uninstall_helm_kafka_controller
    uninstall_helm_kafka_broker
}

redis_up() {
    install_helm_redis
}

redis_down() {
    uninstall_helm_redis
}

mongodb_up() {
    install_helm_mongodb
}

mongodb_down() {
    uninstall_helm_mongodb
}

if [ "$CLUSTER" = "all" ]; then
    if [ "$ACTION" = "start" ]; then

        if [ -n "$PRESET" ]; then
            print_yellow "Generating cluster presets..." 1
            kafka_preset
            redis_preset
            mongodb_preset
            localhost_preset
            nginx_cluster_preset
            print_yellow "Cluster presets generated" 1
        fi

        kafka_up
        redis_up
        mongodb_up
        localhost_up
        nginx_cluster_up
    fi

    if [ "$ACTION" = "stop" ]; then
        kafka_down
        redis_down
        mongodb_down
        localhost_down
        nginx_cluster_down
    fi
else
    for service in $(echo "$CLUSTER" | tr ',' ' '); do        
        if [ "$ACTION" = "start" ]; then
            if [ "$service" = "kafka" ]; then
                if [ "$PRESET" = "true" ]; then
                    print_yellow "Generating Kafka cluster presets..." 1
                    kafka_preset
                    print_yellow "Kafka cluster presets generated" 1
                fi
                kafka_up
            fi

            if [ "$service" = "mongodb" ]; then
                if [ "$PRESET" = "true" ]; then
                    print_yellow "Generating MongoDB cluster presets..." 1
                    mongodb_preset
                    print_yellow "MongoDB cluster presets generated" 1
                fi
                mongodb_up
            fi

            if [ "$service" = "redis" ]; then
                if [ "$PRESET" = "true" ]; then
                    print_yellow "Generating Redis cluster presets..." 1
                    redis_preset
                    print_yellow "Redis cluster presets generated" 1
                fi
                redis_up
            fi

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
        fi

        if [ "$ACTION" = "stop" ]; then
            if [ "$service" = "kafka" ]; then
                kafka_down
            fi

            if [ "$service" = "mongodb" ]; then
                mongodb_down
            fi

            if [ "$service" = "redis" ]; then
                redis_down
            fi

            if [ "$service" = "localhost" ]; then
                localhost_down
            fi

            if [ "$service" = "nginx" ]; then
                nginx_cluster_down
            fi
        fi
    done
fi
