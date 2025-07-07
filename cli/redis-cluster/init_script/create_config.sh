#!/bin/sh

set -e

cd "$(dirname "$0")"

EXPORT_FILE_PATH="../../../tmp/redis-cluster"

mkdir -p "$EXPORT_FILE_PATH"

kubectl create configmap "{{ .Values.configMapName }}" \
  --from-file=commando.sh \
  --from-file=global_tools.sh \
  --from-file=cluster_tools.sh \
  --from-file=cluster_health.sh \
  --from-file=init_cluster.sh \
  --from-file=default_cluster.sh \
  --from-file=orchestrate.sh \
  --from-file=prestop.sh \
  --from-file=cluster_scaling.sh \
  --namespace="{{ .Values.namespace }}" \
  --from-literal=timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
  --dry-run=client -o yaml | sed '/creationTimestamp: null/d' > "$EXPORT_FILE_PATH/configmap.yaml"

HELM_REDIS_PATH="../../../helm/redis-cluster/templates"

cp "$EXPORT_FILE_PATH/configmap.yaml" "$HELM_REDIS_PATH"