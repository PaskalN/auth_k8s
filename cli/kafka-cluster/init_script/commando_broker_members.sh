#!/bin/sh

set -e


# CONTROLLER SETUP
# POD_NAME CHECKER
if [ -z "$POD_NAME_CONTROLLER" ]; then
    echo "POD_NAME_CONTROLLER is missing: Please privide value!"
    exit 1
fi

# SERVICE_NAME CHECKER
if [ -z "$SERVICE_NAME" ]; then
    echo "SERVICE_NAME is missing: Please privide value!"
    exit 1
fi

# NAMESPACE CHECKER
if [ -z "$NAMESPACE" ]; then
    echo "NAMESPACE is missing: Please privide value!"
    exit 1
fi

# CONTROLLER_NAMESPACE CHECKER
if [ -z "$CONTROLLER_NAMESPACE" ]; then
    echo "CONTROLLER_NAMESPACE is missing: Please privide value!"
    exit 1
fi

# CONTROLLER_REPLICAS CHECKER
if [ -z "$CONTROLLER_REPLICAS" ]; then
    echo "CONTROLLER_REPLICAS is missing: Please privide value!"
    exit 1
fi

# CONTROLLER_SERVICE CHECKER
if [ -z "$CONTROLLER_SERVICE" ]; then
    echo "CONTROLLER_SERVICE is missing: Please privide value!"
    exit 1
fi

KAFKA_CONTROLLER_SET_MEMBERS=$(
  awk -v replicas="$CONTROLLER_REPLICAS" -v node_name="$POD_NAME_CONTROLLER" -v service_name="$CONTROLLER_SERVICE" -v namespace="$CONTROLLER_NAMESPACE" '
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

# BROKER SETUP
KAFKA_NODE_ID=$(( ${POD_NAME_INDEX##*-} + 1 ))
POD_NAME="${POD_NAME_INDEX%-[0-9]*}"

if [ -z "$POD_NAME" ]; then
    echo "POD_NAME is missing: Please privide value!"
    exit 1
fi

if [ -z "$REPLICAS" ]; then
    echo "REPLICAS is missing: Please privide value!"
    exit 1
fi

KAFKA_BROKER_SET_MEMBERS=$(
  awk -v controller_replicas="$CONTROLLER_REPLICAS" -v replicas="$REPLICAS" -v node_name="$POD_NAME" -v service_name="$SERVICE_NAME" -v namespace="$NAMESPACE" '
    BEGIN {
        sep = ""

        for (i = 0; i < replicas; i++) {
            next_pod_number = controller_replicas + 1 + i
            printf("%s%d@%s-%d.%s.%s.svc.cluster.local:9093", sep, next_pod_number , node_name, i, service_name, namespace)
            sep = ","
        }
    }
  '
)

echo "KAFKA_CONTROLLER_SET_MEMBERS: $KAFKA_CONTROLLER_SET_MEMBERS"
echo "KAFKA_BROKER_SET_MEMBERS: $KAFKA_BROKER_SET_MEMBERS"
echo "KAFKA_NODE_ID: $KAFKA_NODE_ID"
echo "POD_NAME: $POD_NAME"

export KAFKA_BROKER_SET_MEMBERS
export KAFKA_NODE_ID
export POD_NAME