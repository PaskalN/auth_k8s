#!/bin/sh

set -e

kill_kafka_controller_cluster() {
    echo "Deleting Kafka controller service..."
    kubectl delete svc kafka-service-controller -n authentication --ignore-not-found

    echo "Deleting Kafka controller statefulset..."
    kubectl delete statefulset kafka-controller-node -n authentication --ignore-not-found

    echo "Deleting Kafka init configmap..."
    kubectl delete configmap kafka-init-scripts -n authentication --ignore-not-found

    echo "Deleting Kafka cluster secrets..."
    kubectl delete secret kafka-cluster-secrets -n authentication --ignore-not-found

    echo "Deleting Kafka Controller PVCs..."
    PVCs=$(kubectl get pvc -n authentication --no-headers -o custom-columns=:metadata.name | grep kafka-controller)
    if [ -n "$PVCs" ]; then
        echo "Deleting the following PVCs:"
        echo "$PVCs"
        echo "$PVCs" | xargs -r kubectl delete pvc -n authentication
    else
        echo "No Kafka controller PVCs found to delete."
    fi
}

kill_kafka_broker_cluster() {
    echo "Deleting Kafka broker service..."
    kubectl delete svc kafka-service-broker -n authentication --ignore-not-found

    echo "Deleting Kafka broker statefulset..."
    kubectl delete statefulset kafka-broker-node -n authentication --ignore-not-found

    echo "Deleting Kafka init configmap..."
    kubectl delete configmap kafka-init-scripts -n authentication --ignore-not-found

    echo "Deleting Kafka cluster secrets..."
    kubectl delete secret kafka-cluster-secrets -n authentication --ignore-not-found

    echo "Deleting Kafka Broker PVCs..."
    PVCs=$(kubectl get pvc -n authentication --no-headers -o custom-columns=:metadata.name | grep kafka-broker)
    if [ -n "$PVCs" ]; then
        echo "Deleting the following PVCs:"
        echo "$PVCs"
        echo "$PVCs" | xargs -r kubectl delete pvc -n authentication
    else
        echo "No Kafka broker PVCs found to delete."
    fi
}

kill_mongodb_cluster() {
    echo "Deleting MongoDB service..."
    kubectl delete svc mongo-service -n authentication --ignore-not-found

    echo "Deleting MongoDB statefulset..."
    kubectl delete statefulset mongo-node -n authentication --ignore-not-found

    echo "Deleting MongoDB init configmap..."
    kubectl delete configmap mongo-init-scripts -n authentication --ignore-not-found

    echo "Deleting MongoDB cluster secrets..."
    kubectl delete secret mongo-cluster-secrets -n authentication --ignore-not-found

    echo "Deleting MongoDB PVCs..."
    PVCs=$(kubectl get pvc -n authentication --no-headers -o custom-columns=:metadata.name | grep mongo-node)
    if [ -n "$PVCs" ]; then
        echo "Deleting the following PVCs:"
        echo "$PVCs"
        echo "$PVCs" | xargs -r kubectl delete pvc -n authentication
    else
        echo "No MongoDB PVCs found to delete."
    fi
}

kill_redis_cluster() {
    echo "Deleting Redis service..."
    kubectl delete svc redis-service -n authentication --ignore-not-found

    echo "Deleting Redis statefulset..."
    kubectl delete statefulset redis-node -n authentication --ignore-not-found

    echo "Deleting Redis init configmap..."
    kubectl delete configmap redis-init-scripts -n authentication --ignore-not-found

    echo "Deleting Redis cluster secrets..."
    kubectl delete secret redis-cluster-secrets -n authentication --ignore-not-found

    echo "Deleting Redis PVCs..."
    PVCs=$(kubectl get pvc -n authentication --no-headers -o custom-columns=:metadata.name | grep redis-node)
    if [ -n "$PVCs" ]; then
        echo "Deleting the following PVCs:"
        echo "$PVCs"
        echo "$PVCs" | xargs -r kubectl delete pvc -n authentication
    else
        echo "No Redis PVCs found to delete."
    fi
}

# Kill Evrething if such
kill_kafka_controller_cluster
kill_kafka_broker_cluster
kill_mongodb_cluster
kill_redis_cluster