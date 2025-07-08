#!/bin/sh

set -e

cd "$(dirname "$0")"

# 1. Generate all additional values
echo "Generating Kafka UUIDs..."
cli/kafka-cluster/init_script/generate_uuid_values.sh

echo "Generating Kafka config..."
cli/kafka-cluster/init_script/create_config.sh

echo "Generating Mongo keyfiles..."
cli/mongo-cluster/generate_keyfiles.sh

echo "Generating Redis certificates..."
cli/redis-cluster/generate_certificate.sh

# 2. Generate all sh files and support files
echo "Creating Mongo config..."
cli/mongo-cluster/init-script/create-config.sh

echo "Creating Redis config..."
cli/redis-cluster/init-script/create-config.sh

echo "Creating MongoDB config..."
cli/mongo-cluster/init-script/create-config.sh

echo "Starting Kafka Controller Cluster ..."
helm install kafka-controller ./helm/kafka-controller/ --values ./helm/kafka-controller/values.yaml --values ./helm/kafka-controller/values_uuids.yaml

echo "Starting Kafka Broker Cluster ..."
helm install kafka-broker ./helm/kafka-broker/ --values ./helm/kafka-broker/values.yaml --values ./helm/kafka-broker/values_uuids.yaml

echo "Starting MongoDB Cluster ..."
helm install mongodb-cluster ./helm/mongodb-cluster/ --values ./helm/mongodb-cluster/values.yaml --values ./helm/mongodb-cluster/values_secrets.yaml

echo "Starting Redis Cluster ..."
helm install redis-cluster ./helm/redis-cluster/ --values ./helm/redis-cluster/values.yaml --values ./helm/redis-cluster/values_secrets.yaml