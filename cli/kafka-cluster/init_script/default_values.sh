#!/bin/sh

set -e

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

# The Kafka configuration parameter offsets.topic.replication.factor controls how many replicas are created for the __consumer_offsets internal topic in Kafka.
# Kafka uses a special internal topic called __consumer_offsets to store the committed offsets of consumer groups — i.e., 
# the positions in topics that each consumer group has read up to. This is essential for fault tolerance, rebalancing, and at-least-once delivery semantics.
export KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR

# The Kafka configuration parameter transaction.state.log.replication.factor controls 
# how many replicas Kafka will create for the internal topic that stores transactional state, 
# which is crucial when using Kafka transactions (i.e., exactly-once semantics).

# Defines how many replicas each partition of the __transaction_state topic should have.
# A replication factor >1 ensures availability and fault-tolerance for the transactional system.
export KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR

# The Kafka config parameter transaction.state.log.min.isr sets the minimum number of in-sync replicas (ISRs) 
# that must be available for Kafka to commit writes to the internal __transaction_state topic, which is used for managing transactional state.
# It defines the minimum number of replicas that must be in-sync (i.e., caught up with the leader) for a write to be accepted on the __transaction_state topic.
export KAFKA_TRANSACTION_STATE_LOG_MIN_ISR

# The Kafka broker configuration num.network.threads sets the number of threads Kafka uses to handle network requests—specifically, 
# it controls how many threads Kafka uses to:

# Accept client connections
# Read requests (produce, fetch, metadata, etc.)
# Send responses
export KAFKA_NUM_NETWORK_THREADS

# The number of threads that the server uses for processing requests, which may include disk I/O
export KAFKA_NUM_IO_THREADS

# The send buffer (SO_SNDBUF) used by the socket server
export KAFKA_SOCKET_SEND_BUFFER_BYTES

# The receive buffer (SO_RCVBUF) used by the socket server
export KAFKA_RECIEVE_BUFFER_BYTES

# The maximum size of a request that the socket server will accept (protection against OOM)
export KAFKA_REQUEST_MAX_BYTES

# The default number of log partitions per topic. More partitions allow greater
# parallelism for consumption, but this will also result in more files across
# the brokers.
export KAFKA_NUM_PARTITIONS

# The number of threads per data directory to be used for log recovery at startup and flushing at shutdown.
# This value is recommended to be increased for installations with data dirs located in RAID array.
export KAFKA_RECOVERY_THREADS_PER_DATA_DIR

#  Kafka configuration property used by Debezium or other Kafka-based data-sharing frameworks that rely on shared coordination topics.
# This tells Kafka to replicate the shared coordinator state topic across N brokers, ensuring high availability.
export KAFKA_SHARE_COORDINATOR_STATE_TOPIC_REPLICATION_FACTOR

# The minimum number of in-sync replicas (ISR) required for the coordinator state topic to accept writes.
# It’s typically used in systems like Debezium, Kafka Connect, or any Kafka-based coordination mechanism that creates internal topics for coordination or metadata sharing.
export KAFKA_SHARE_COORDINATOR_STATE_TOPIC_MIN_ISR

# The minimum age of a log file to be eligible for deletion due to age
export KAFKA_RETENTION_HOURS

# The interval at which log segments are checked to see if they can be deleted according
# to the retention policies
export KAFKA_RETENTION_CHECK_INTERVAL_MS

# The maximum size of a log segment file. When this size is reached a new log segment will be created.
export KAFKA_LOG_SEGMENT_BYTES