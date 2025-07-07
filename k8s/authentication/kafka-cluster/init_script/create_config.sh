#!/bin/sh

set -e

cd "$(dirname "$0")" 

kubectl create configmap kafka-init-scripts \
    --from-file=commando_controller_members.sh \
    --from-file=commando_broker_members.sh \
    --from-file=commando.sh \
    --from-file=controller.properties \
    --from-file=broker.properties \
    --namespace=authentication \
    --from-literal=timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    --dry-run=client -o yaml | sed '/creationTimestamp: null/d' > ../configmap.yaml
