#!/bin/sh

set -e

cd "$(dirname "$0")"

EXPORT_FILE_PATH="../../../tmp/mongodb-cluster"

mkdir -p "$EXPORT_FILE_PATH"

kubectl create configmap "{{ .Values.configMapName }}" \
  --from-file=sh-tools.sh \
  --from-file=init-cluster.sh \
  --from-file=lifecycle-prestop.sh \
  --from-file=js/add_node.js \
  --from-file=js/init_cluster.js \
  --from-file=js/tools.js \
  --from-file=js/prestop.js \
  --namespace="{{ .Values.namespace }}" \
  --from-literal=timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
  --dry-run=client -o yaml | sed '/creationTimestamp: null/d' > "$EXPORT_FILE_PATH/configmap.yaml"

HELM_MONGODB_PATH="../../../helm/mongodb-cluster/templates"

cp "$EXPORT_FILE_PATH/configmap.yaml" "$HELM_MONGODB_PATH"
