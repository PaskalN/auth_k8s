#!/bin/sh

set -e

cd "$(dirname "$0")"

EXPORT_FILE_PATH="../../../tmp/kafka-cluster"

mkdir -p "$EXPORT_FILE_PATH"

kubectl create configmap "{{ .Values.configMapName }}" \
  --from-file=global_tools.sh \
  --from-file=include.sh \
  --from-file=commando.sh \
  --from-file=default_values.sh \
  --from-file=environment_checker.sh \
  --from-file=broker_server_properties.sh \
  --from-file=commando_broker_members.sh \
  --from-file=controller_server_properties.sh \
  --from-file=commando_controller_members.sh \
  --from-file=debug.sh \
  --from-file=init_kafka.sh \
  --from-file=controller.properties \
  --from-file=broker.properties \
  --namespace="{{ .Values.namespace }}" \
  --from-literal=timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
  --dry-run=client -o yaml | sed '/creationTimestamp: null/d' > "$EXPORT_FILE_PATH/configmap.yaml"

HELM_KAFKA_CONTROLLER_PATH="../../../helm/kafka-controller/templates"
HELM_KAFKA_BROKER_PATH="../../../helm/kafka-broker/templates"

cp "$EXPORT_FILE_PATH/configmap.yaml" "$HELM_KAFKA_CONTROLLER_PATH"
cp "$EXPORT_FILE_PATH/configmap.yaml" "$HELM_KAFKA_BROKER_PATH"