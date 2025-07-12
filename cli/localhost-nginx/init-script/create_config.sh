#!/bin/sh

set -e

cd "$(dirname "$0")"

EXPORT_FILE_PATH="../../../tmp/localhost-nginx"

mkdir -p "$EXPORT_FILE_PATH"

{
    echo "{{- $ := . }}"
    kubectl create configmap "{{ .Values.configMapName }}" \
    --from-file=nginx.conf \
    --from-file=ports.conf \
    --from-file=locations.conf \
    --from-file=stream.conf \
    --namespace="{{ .Values.namespace }}" \
    --from-literal=timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    --dry-run=client -o yaml | 
    sed '/creationTimestamp: null/d'
} > "$EXPORT_FILE_PATH/configmap.yaml"

HELM_LOCALHOST_NGINX_PATH="../../../helm/localhost-nginx/templates"

cp "$EXPORT_FILE_PATH/configmap.yaml" "$HELM_LOCALHOST_NGINX_PATH"