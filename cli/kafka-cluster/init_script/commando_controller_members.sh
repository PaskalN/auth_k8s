#!/bin/sh

set -e

KAFKA_NODE_ID=$(( ${POD_NAME_INDEX##*-} + 1 ))
POD_NAME="${POD_NAME_INDEX%-[0-9]*}"

# POD_NAME CHECKER
if [ -z "$POD_NAME" ]; then
    print_red "POD_NAME is missing: Please privide value!" 1
    exit 1
fi

# SERVICE_NAME CHECKER
if [ -z "$SERVICE_NAME" ]; then
    print_red "SERVICE_NAME is missing: Please privide value!" 1
    exit 1
fi

# NAMESPACE CHECKER
if [ -z "$NAMESPACE" ]; then
    print_red "NAMESPACE is missing: Please privide value!" 1
    exit 1
fi

# REPLICAS CHECKER
if [ -z "$REPLICAS" ]; then
    print_red "REPLICAS is missing: Please privide value!" 1
    exit 1
fi

KAFKA_CONTROLLER_SET_MEMBERS=$(
  awk -v replicas="$REPLICAS" -v node_name="$POD_NAME" -v service_name="$SERVICE_NAME" -v namespace="$NAMESPACE" '
    BEGIN {
        sep = ""
        for (i = 0; i < replicas; i++) {
            printf("%s%d@%s-%d.%s.%s.svc.cluster.local:9093", sep, i+1, node_name, i, service_name, namespace)
            sep = ","
        }
    }
  '
)

export KAFKA_CONTROLLER_SET_MEMBERS
export KAFKA_NODE_ID
export POD_NAME