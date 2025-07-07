#!/bin/sh

set -e

cd "$(dirname "$0")"

echo "Stoping Kafka Controller Cluster ..."
helm uninstall kafka-controller

echo "Stoping Kafka Broker Cluster ..."
helm uninstall kafka-broker

echo "Stoping MongoDB Cluster ..."
helm uninstall mongodb-cluster

echo "Stoping Redis Cluster ..."
helm uninstall redis-cluster