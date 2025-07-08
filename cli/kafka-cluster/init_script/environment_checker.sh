#!/bin/sh

set -e

environment_checker() {

    if [ -z "$KAFKA_CLUSTER_ID" ]; then
        print_red "KAFKA_CLUSTER_ID is not defined!" 1
        exit 1
    fi

    # NODE ID CHECKER
    if [ -z "$KAFKA_NODE_ID" ]; then
        print_red "KAFKA_NODE_ID is missing: Must be numeric value e.g: 1,2,3,4,5,6..." 1
        exit 1
    elif ! echo "$KAFKA_NODE_ID" | grep -Eq '^[0-9]+$'; then
        print_red "KAFKA_NODE_ID must be a numeric value e.g: 1,2,3,4,5,6..." 1
        exit 1
    elif [ "$KAFKA_NODE_ID" -le 0 ]; then
        print_red "KAFKA_NODE_ID must be greater than 0" 1
        exit 1
    fi

    # KAFKA_LISTENERS CHECKER
    if [ -z "$KAFKA_LISTENERS" ]; then
        print_red "KAFKA_LISTENERS is missing: Please privide value: e.g: CONTROLLER://0.0.0.0:9093 or BROKER://0.0.0.0:9093" 1
        exit 1
    fi

    # KAFKA_LISTENERS CHECKER
    if [ "$KAFKA_PROCESS_ROLES" != "broker" ] && [ "$KAFKA_PROCESS_ROLES" != "controller" ]; then
    print_red "Invalid KAFKA_PROCESS_ROLES: Must be either 'broker' or 'controller e.g: KAFKA_PROCESS_ROLES = broker'" 1
    exit 1
    fi


    # KAFKA_CONTROLLER_LISTENER_NAMES CHECKER
    if [ -z "$KAFKA_CONTROLLER_LISTENER_NAMES" ]; then
    print_red "KAFKA_CONTROLLER_LISTENER_NAMES is missing: Must be string value e.g: CONTROLLER or MYAPPCONTROLLER or BROKER or MYAPPBROKER ..." 1
    exit 1
    fi


    # KAFKA_CLUSTER_ID CHECKER
    if [ -z "$KAFKA_CLUSTER_ID" ]; then
    print_red "KAFKA_CLUSTER_ID is missing: Must be random string value of 22 chars string e.g: q8e655wHON-6FzkuXP4iZA" 1
    exit 1
    fi


    # Must have the set of members like: 1@[dns_controller]:[port], 2@[dns_controller]:[port], 3@[dns_controller]:[port] ...
    if [ -z "$KAFKA_CONTROLLER_SET_MEMBERS" ]; then
        print_red "KAFKA_CONTROLLER_SET_MEMBERS is invalid!" 1
        exit 1
    fi


    # GENERATE THE KAFKA_ADVERTISED_LISTENERS
    KAFKA_ADVERTISED_LISTENERS=""

    # GENERATE THE KAFKA_ADVERTISED_LISTENERS
    # FOR CONTROLLER
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

    # GENERATE THE KAFKA_ADVERTISED_LISTENERS
    # FOR BROKERS
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

        if [ -z "$KAFKA_ADVERTISED_LISTENERS" ]; then
            print_red "Can't determinate the advert. listener" 1
            exit 1
        fi
    fi


    # SET THE CORRECT NODE ID IF THE ROLE IS BROKER
    if [ "$KAFKA_PROCESS_ROLES" = "broker" ]; then

        set -- $(split_string "$KAFKA_CONTROLLER_SET_MEMBERS" ",")
        CONTROLLERS_COUNT=$#

        KAFKA_NODE_ID=$((CONTROLLERS_COUNT + KAFKA_NODE_ID))
    fi

    # GET THE SET OF COMMA SEPARATED CONTROLLER DNS
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

    # Information about the KRaft controller quorum.
    KAFKA_CONTROLLER_QUORUM_BOOTSTRAP_SERVERS="$(echo "$KAFKA_CONTROLLER_SET_MEMBERS" | sed 's/[^,]*@//g')"

    export KAFKA_INITIAL_CONTROLLERS
    export KAFKA_CONTROLLER_QUORUM_BOOTSTRAP_SERVERS
}