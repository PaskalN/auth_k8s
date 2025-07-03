#!/bin/sh

set -e

cd "$(dirname "$0")" 

kubectl create configmap redis-init-scripts \
  --from-file=commando.sh \
  --from-file=global_tools.sh \
  --from-file=cluster_tools.sh \
  --from-file=cluster_health.sh \
  --from-file=init_cluster.sh \
  --from-file=default_cluster.sh \
  --from-file=orchestrate.sh \
  --from-file=prestop.sh \
  --from-file=cluster_scaling.sh \
  --namespace=authentication \
  --from-literal=timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
  --dry-run=client -o yaml | sed '/creationTimestamp: null/d' > ../configmap.yaml