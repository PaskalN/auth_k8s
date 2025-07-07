#!/bin/sh

set -e

PWD=$(pwd)
CLUSTERS_PATH="$PWD/k8s/authentication"

build_kafka_configmap() {
    "$PWD"/k8s/authentication/kafka-cluster/init_script/create_config.sh
}


build_redis_configmap() {
    "$PWD"/k8s/authentication/redis-cluster/init_script/create_config.sh
}

start_kafka_controller_cluster() {
    CLUSTER_PATH="$CLUSTERS_PATH/kafka-cluster"

    echo "Applying Kafka controller secret..."
    kubectl apply -f "$CLUSTER_PATH/secret.yaml" && \
    echo "Applying Kafka controller configmap..." && \
    kubectl apply -f "$CLUSTER_PATH/configmap.yaml" && \
    echo "Applying Kafka controller service..." && \
    kubectl apply -f "$CLUSTER_PATH/controller-service.yaml" && \
    echo "Applying Kafka controller statefulset..." && \
    kubectl apply -f "$CLUSTER_PATH/controller-statefulset.yaml"
}

start_kafka_broker_cluster() {
    CLUSTER_PATH="$CLUSTERS_PATH/kafka-cluster"

    echo "Applying Kafka broker secret..."
    kubectl apply -f "$CLUSTER_PATH/secret.yaml" && \
    echo "Applying Kafka broker configmap..." && \
    kubectl apply -f "$CLUSTER_PATH/configmap.yaml" && \
    echo "Applying Kafka broker service..." && \
    kubectl apply -f "$CLUSTER_PATH/broker-service.yaml" && \
    echo "Applying Kafka broker statefulset..." && \
    kubectl apply -f "$CLUSTER_PATH/broker-statefulset.yaml"
}

start_mongodb_cluster() {
    CLUSTER_PATH="$CLUSTERS_PATH/mongo-cluster"

    echo "Applying MongoDB secret..."
    kubectl apply -f "$CLUSTER_PATH/secret.yaml" && \
    echo "Applying MongoDB configmap..." && \
    kubectl apply -f "$CLUSTER_PATH/configmap.yaml" && \
    echo "Applying MongoDB service..." && \
    kubectl apply -f "$CLUSTER_PATH/service.yaml" && \
    echo "Applying MongoDB statefulset..." && \
    kubectl apply -f "$CLUSTER_PATH/statefulset.yaml"
}

start_redis_cluster() {
    CLUSTER_PATH="$CLUSTERS_PATH/redis-cluster"

    # echo "Applying Redis secret..."
    # kubectl apply -f "$CLUSTER_PATH/secret.yaml" && \
    echo "Applying Redis configmap..." && \
    kubectl apply -f "$CLUSTER_PATH/configmap.yaml" && \
    echo "Applying Redis service..." && \
    kubectl apply -f "$CLUSTER_PATH/service.yaml" && \
    echo "Applying Redis statefulset..." && \
    kubectl apply -f "$CLUSTER_PATH/statefulset.yaml"
}

# Create kafka config map
build_kafka_configmap

# Create redis config map
build_redis_configmap

# # Run all clusters
# start_kafka_controller_cluster
# start_kafka_broker_cluster
# start_mongodb_cluster
# start_redis_cluster
