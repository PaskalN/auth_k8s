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

. "$PRESET_DIR/kafka_cluster.sh"
. "$PRESET_DIR/mongo_cluster.sh"
. "$PRESET_DIR/redis_cluster.sh"

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
            print_yellow "Cluster presets generated" 1
        fi

        kafka_up
        redis_up
        mongodb_up
    fi

    if [ "$ACTION" = "stop" ]; then
        kafka_down
        redis_down
        mongodb_down
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
        fi
    done
fi
