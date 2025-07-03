#!/bin/sh

set -e

if [ "$KAFKA_PROCESS_ROLES" = "controller" ]; then
    source "${USER_CONFIG_DIR}/commando/commando_controller_members.sh"
fi

if [ "$KAFKA_PROCESS_ROLES" = "broker" ]; then
    source "${USER_CONFIG_DIR}/commando/commando_broker_members.sh"
fi

split_string() {
    input="$1"
    separator="$2"
    old_IFS="$IFS"
    IFS="$separator"
    set -- $input
    IFS="$old_IFS"

    # Print space-separated items
    for s in "$@"; do
        echo "$s"
    done
}

KAFKA_ADVERTISED_LISTENERS=""

if [ -z "$KAFKA_CLUSTER_ID" ]; then
    echo "KAFKA_CLUSTER_ID is not defined!"
    exit 1
fi

# NODE ID CHECKER
if [ -z "$KAFKA_NODE_ID" ]; then
    echo "KAFKA_NODE_ID is missing: Must be numeric value e.g: 1,2,3,4,5,6..."
    exit 1
elif ! echo "$KAFKA_NODE_ID" | grep -Eq '^[0-9]+$'; then
    echo "KAFKA_NODE_ID must be a numeric value e.g: 1,2,3,4,5,6..."
    exit 1
elif [ "$KAFKA_NODE_ID" -le 0 ]; then
    echo "KAFKA_NODE_ID must be greater than 0"
    exit 1
fi

# KAFKA_LISTENERS CHECKER
if [ -z "$KAFKA_LISTENERS" ]; then
    echo "KAFKA_LISTENERS is missing: Please privide value: e.g: CONTROLLER://0.0.0.0:9093 or BROKER://0.0.0.0:9093"
    exit 1
fi

# KAFKA_LISTENERS CHECKER
if [ "$KAFKA_PROCESS_ROLES" != "broker" ] && [ "$KAFKA_PROCESS_ROLES" != "controller" ]; then
  echo "Invalid KAFKA_PROCESS_ROLES: Must be either 'broker' or 'controller e.g: KAFKA_PROCESS_ROLES = broker'"
  exit 1
fi


# KAFKA_CONTROLLER_LISTENER_NAMES CHECKER
if [ -z "$KAFKA_CONTROLLER_LISTENER_NAMES" ]; then
  echo "KAFKA_CONTROLLER_LISTENER_NAMES is missing: Must be string value e.g: CONTROLLER or MYAPPCONTROLLER or BROKER or MYAPPBROKER ..."
  exit 1
fi


# KAFKA_CLUSTER_ID CHECKER
if [ -z "$KAFKA_CLUSTER_ID" ]; then
  echo "KAFKA_CLUSTER_ID is missing: Must be random string value of 22 chars string e.g: q8e655wHON-6FzkuXP4iZA"
  exit 1
fi



# Must have the set of members like: 1@[dns_controller]:[port], 2@[dns_controller]:[port], 3@[dns_controller]:[port] ...
if [ -z "$KAFKA_CONTROLLER_SET_MEMBERS" ]; then
    exit 1
fi

KAFKA_CONTROLLER_QUORUM_VOTERS="$KAFKA_CONTROLLER_SET_MEMBERS"
KAFKA_CONTROLLER_QUORUM_BOOTSTRAP_SERVERS="$(echo "$KAFKA_CONTROLLER_SET_MEMBERS" | sed 's/[^,]*@//g')"


# GENERATE THE KAFKA_ADVERTISED_LISTENERS
if [ "$KAFKA_PROCESS_ROLES" = "controller" ]; then

    # Loop through the list and find the matching entry
    for item in $(split_string "$KAFKA_CONTROLLER_SET_MEMBERS" ","); do
        node_id="${item%%@*}"
        if [ "$node_id" = "$KAFKA_NODE_ID" ]; then
            value="${item#*@}"
            KAFKA_ADVERTISED_LISTENERS="CONTROLLER://$value"
        fi
    done
fi

if [ "$KAFKA_PROCESS_ROLES" = "broker" ]; then

    CONTROLLER_REPLICAS=${CONTROLLER_REPLICAS:-0}
    ACTUAL_BROKER_NODE_N=$(( KAFKA_NODE_ID + CONTROLLER_REPLICAS ))

    

    KAFKA_ADVERTISED_LISTENERS=$(
        awk -v broker_node_n="$ACTUAL_BROKER_NODE_N" -v kafka_broker_members="$KAFKA_BROKER_SET_MEMBERS" '
        BEGIN {
            n = split(kafka_broker_members, member_set, ",")
            for (i = 1; i <= n; i++) {
                split(member_set[i], parts, "@")
                node_id = parts[1]
                address = parts[2]

                if (node_id == broker_node_n) {
                    print "PLAINTEXT://" address
                    exit
                }
            }
        }
        '
    )
fi

if [ -z "$KAFKA_ADVERTISED_LISTENERS" ]; then
    echo "Can't determinate the advert. listener"
    exit 1
fi


if [ "$KAFKA_PROCESS_ROLES" = "broker" ]; then
    set -- $(split_string "$KAFKA_CONTROLLER_SET_MEMBERS" ",")
    CONTROLLERS_COUNT=$#

    KAFKA_NODE_ID=$((CONTROLLERS_COUNT + KAFKA_NODE_ID))
fi

KAFKA_INITIAL_CONTROLLERS=$(
  awk -F',' '
    BEGIN {
        split("'"$KAFKA_CONTROLLER_SET_MEMBERS"'", members, ",")
        split("'"$KAFKA_CONTROLLER_UUIDs"'", uuids, ",")
        for (i in members) {
            split(uuids[i], u_parts, "@")
            out = members[i] ":" u_parts[2]
            printf("%s%s", sep, out)
            sep = ","
        }
    }
  '
)

KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=${KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR:-1}
KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR=${KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR:-1}
KAFKA_TRANSACTION_STATE_LOG_MIN_ISR=${KAFKA_TRANSACTION_STATE_LOG_MIN_ISR:-1}
KAFKA_NUM_NETWORK_THREADS=${KAFKA_NUM_NETWORK_THREADS:-3}
KAFKA_NUM_IO_THREADS=${KAFKA_NUM_IO_THREADS:-8}
KAFKA_SOCKET_SEND_BUFFER_BYTES=${KAFKA_SOCKET_SEND_BUFFER_BYTES:-102400}
KAFKA_RECIEVE_BUFFER_BYTES=${KAFKA_RECIEVE_BUFFER_BYTES:-102400}
KAFKA_REQUEST_MAX_BYTES=${KAFKA_REQUEST_MAX_BYTES:-104857600}
KAFKA_NUM_PARTITIONS=${KAFKA_NUM_PARTITIONS:-1}
KAFKA_RECOVERY_THREADS_PER_DATA_DIR=${KAFKA_RECOVERY_THREADS_PER_DATA_DIR:-1}
KAFKA_SHARE_COORDINATOR_STATE_TOPIC_REPLICATION_FACTOR=${KAFKA_SHARE_COORDINATOR_STATE_TOPIC_REPLICATION_FACTOR:-1}
KAFKA_SHARE_COORDINATOR_STATE_TOPIC_MIN_ISR=${KAFKA_SHARE_COORDINATOR_STATE_TOPIC_MIN_ISR:-1}
KAFKA_RETENTION_HOURS=${KAFKA_RETENTION_HOURS:-168}
KAFKA_RETENTION_CHECK_INTERVAL_MS=${KAFKA_RETENTION_CHECK_INTERVAL_MS:-300000}
KAFKA_LOG_SEGMENT_BYTES=${KAFKA_LOG_SEGMENT_BYTES:-1073741824}

# echo "==============================================="
# echo "==============================================="

# echo "KAFKA_NODE_ID: ${KAFKA_NODE_ID}"
# echo "KAFKA_LISTENERS: ${KAFKA_LISTENERS}"
# echo "KAFKA_PROCESS_ROLES: ${KAFKA_PROCESS_ROLES}"
# echo "KAFKA_CONTROLLER_LISTENER_NAMES: ${KAFKA_CONTROLLER_LISTENER_NAMES}"
# echo "KAFKA_CLUSTER_ID: ${KAFKA_CLUSTER_ID}"
# echo "KAFKA_CONTROLLER_QUORUM_BOOTSTRAP_SERVERS: ${KAFKA_CONTROLLER_QUORUM_BOOTSTRAP_SERVERS}"
# echo "KAFKA_ADVERTISED_LISTENERS: ${KAFKA_ADVERTISED_LISTENERS}"
# echo "KAFKA_INITIAL_CONTROLLERS: ${KAFKA_INITIAL_CONTROLLERS}"
# echo "KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR :${KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR}"
# echo "KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR :${KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR}"
# echo "KAFKA_TRANSACTION_STATE_LOG_MIN_ISR :${KAFKA_TRANSACTION_STATE_LOG_MIN_ISR}"
# echo "KAFKA_NUM_NETWORK_THREADS :${KAFKA_NUM_NETWORK_THREADS}"
# echo "KAFKA_NUM_IO_THREADS :${KAFKA_NUM_IO_THREADS}"
# echo "KAFKA_SOCKET_SEND_BUFFER_BYTES :${KAFKA_SOCKET_SEND_BUFFER_BYTES}"
# echo "KAFKA_RECIEVE_BUFFER_BYTES :${KAFKA_RECIEVE_BUFFER_BYTES}"
# echo "KAFKA_REQUEST_MAX_BYTES :${KAFKA_REQUEST_MAX_BYTES}"
# echo "KAFKA_NUM_PARTITIONS :${KAFKA_NUM_PARTITIONS}"
# echo "KAFKA_RECOVERY_THREADS_PER_DATA_DIR :${KAFKA_RECOVERY_THREADS_PER_DATA_DIR}"
# echo "KAFKA_SHARE_COORDINATOR_STATE_TOPIC_REPLICATION_FACTOR :${KAFKA_SHARE_COORDINATOR_STATE_TOPIC_REPLICATION_FACTOR}"
# echo "KAFKA_SHARE_COORDINATOR_STATE_TOPIC_MIN_ISR :${KAFKA_SHARE_COORDINATOR_STATE_TOPIC_MIN_ISR}"
# echo "KAFKA_RETENTION_HOURS :${KAFKA_RETENTION_HOURS}"
# echo "KAFKA_RETENTION_CHECK_INTERVAL_MS :${KAFKA_RETENTION_CHECK_INTERVAL_MS}"
# echo "KAFKA_LOG_SEGMENT_BYTES :${KAFKA_LOG_SEGMENT_BYTES}"
# echo "KAFKA_CONTROLLER_QUORUM_VOTERS :${KAFKA_CONTROLLER_QUORUM_VOTERS}"

# echo "==============================================="
# echo "==============================================="

# Read template and replace placeholders
if [ "$KAFKA_PROCESS_ROLES" = "controller" ]; then
    sed -e "s#{{KAFKA_NODE_ID}}#$KAFKA_NODE_ID#g" \
        -e "s#{{KAFKA_LOG_DIR}}#$KAFKA_LOG_DIR#g" \
        -e "s#{{KAFKA_LISTENERS}}#$KAFKA_LISTENERS#g" \
        -e "s#{{KAFKA_PROCESS_ROLES}}#$KAFKA_PROCESS_ROLES#g" \
        -e "s#{{KAFKA_CONTROLLER_LISTENER_NAMES}}#$KAFKA_CONTROLLER_LISTENER_NAMES#g" \
        -e "s#{{KAFKA_CLUSTER_ID}}#$KAFKA_CLUSTER_ID#g" \
        -e "s#{{KAFKA_CONTROLLER_QUORUM_VOTERS}}#$KAFKA_CONTROLLER_QUORUM_VOTERS#g" \
        -e "s#{{KAFKA_ADVERTISED_LISTENERS}}#$KAFKA_ADVERTISED_LISTENERS#g" \
        -e "s#{{KAFKA_CONTROLLER_QUORUM_BOOTSTRAP_SERVERS}}#$KAFKA_CONTROLLER_QUORUM_BOOTSTRAP_SERVERS#g" \
        "$USER_CONFIG_DIR/commando/controller.properties" \
        > "$USER_CONFIG_DIR/server.properties"
fi

if [ "$KAFKA_PROCESS_ROLES" = "broker" ]; then
    sed -e "s#{{KAFKA_NODE_ID}}#$KAFKA_NODE_ID#g" \
        -e "s#{{KAFKA_LOG_DIR}}#$KAFKA_LOG_DIR#g" \
        -e "s#{{KAFKA_LISTENERS}}#$KAFKA_LISTENERS#g" \
        -e "s#{{KAFKA_PROCESS_ROLES}}#$KAFKA_PROCESS_ROLES#g" \
        -e "s#{{KAFKA_CONTROLLER_LISTENER_NAMES}}#$KAFKA_CONTROLLER_LISTENER_NAMES#g" \
        -e "s#{{KAFKA_CLUSTER_ID}}#$KAFKA_CLUSTER_ID#g" \
        -e "s#{{KAFKA_CONTROLLER_QUORUM_VOTERS}}#$KAFKA_CONTROLLER_QUORUM_VOTERS#g" \
        -e "s#{{KAFKA_ADVERTISED_LISTENERS}}#$KAFKA_ADVERTISED_LISTENERS#g" \
        -e "s#{{KAFKA_CONTROLLER_QUORUM_BOOTSTRAP_SERVERS}}#$KAFKA_CONTROLLER_QUORUM_BOOTSTRAP_SERVERS#g" \
        -e "s#{{KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR}}#${KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR}#g" \
        -e "s#{{KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR}}#${KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR}#g" \
        -e "s#{{KAFKA_TRANSACTION_STATE_LOG_MIN_ISR}}#${KAFKA_TRANSACTION_STATE_LOG_MIN_ISR}#g" \
        -e "s#{{KAFKA_NUM_NETWORK_THREADS}}#${KAFKA_NUM_NETWORK_THREADS}#g" \
        -e "s#{{KAFKA_NUM_IO_THREADS}}#${KAFKA_NUM_IO_THREADS}#g" \
        -e "s#{{KAFKA_SOCKET_SEND_BUFFER_BYTES}}#${KAFKA_SOCKET_SEND_BUFFER_BYTES}#g" \
        -e "s#{{KAFKA_RECIEVE_BUFFER_BYTES}}#${KAFKA_RECIEVE_BUFFER_BYTES}#g" \
        -e "s#{{KAFKA_REQUEST_MAX_BYTES}}#${KAFKA_REQUEST_MAX_BYTES}#g" \
        -e "s#{{KAFKA_NUM_PARTITIONS}}#${KAFKA_NUM_PARTITIONS}#g" \
        -e "s#{{KAFKA_RECOVERY_THREADS_PER_DATA_DIR}}#${KAFKA_RECOVERY_THREADS_PER_DATA_DIR}#g" \
        -e "s#{{KAFKA_SHARE_COORDINATOR_STATE_TOPIC_REPLICATION_FACTOR}}#${KAFKA_SHARE_COORDINATOR_STATE_TOPIC_REPLICATION_FACTOR}#g" \
        -e "s#{{KAFKA_SHARE_COORDINATOR_STATE_TOPIC_MIN_ISR}}#${KAFKA_SHARE_COORDINATOR_STATE_TOPIC_MIN_ISR}#g" \
        -e "s#{{KAFKA_RETENTION_HOURS}}#${KAFKA_RETENTION_HOURS}#g" \
        -e "s#{{KAFKA_RETENTION_CHECK_INTERVAL_MS}}#${KAFKA_RETENTION_CHECK_INTERVAL_MS}#g" \
        -e "s#{{KAFKA_LOG_SEGMENT_BYTES}}#${KAFKA_LOG_SEGMENT_BYTES}#g" \
        "$USER_CONFIG_DIR/commando/broker.properties" \
        > "$USER_CONFIG_DIR/server.properties"
fi

sleep 2

if [ ! -f "/var/lib/kafka/data/meta.properties" ]; then
    /opt/kafka/bin/kafka-storage.sh format \
        --config "${USER_CONFIG_DIR}/server.properties" \
        --cluster-id "$KAFKA_CLUSTER_ID" \
        --initial-controllers "$KAFKA_INITIAL_CONTROLLERS"
fi

sleep 3

if [ ! -f "${USER_CONFIG_DIR}/server.properties" ]; then
    echo "ERROR: Kafka config not found at ${USER_CONFIG_DIR}/server.properties"
    exit 1
fi

exec /opt/kafka/bin/kafka-server-start.sh "${USER_CONFIG_DIR}/server.properties"