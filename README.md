# Notes: Jul 13 2025

## Project Upgrade

-   Introducing project debug process.
-   Exposing Nginx Loadbalancer to localhost.
-   Nginx Cluster + SSL/TLS auto setup - Loadbalancer
-   Nodejs setup + Debugger

1. Cluster Start / [▶️ Watch demo](screen_logs/ClusterStart.mp4)
2. Project Start / [▶️ Watch demo](screen_logs/ProjectStart.mp4)
3. Start Debugger / [▶️ Watch demo](screen_logs/Debugging.mp4)

In order to start the project you need to download the Start Point NodeJs(Express) project. https://github.com/PaskalN/start-point/tree/main

Create an image by using `npm run build:image:nocache`

In order to start debugger ensure helm file (Start Point) has only one replica and `port_debug` is set to true.

For more details please checkout the `project.drawio` scheme

# Notes: Jul 8 2025

## Project Upgrade

Helm files for each cluster

Better sh generators

Introducing cluster.sh | automate_cli

-   usage: `./cluster.sh --cluster [mongodb, redis, kafka, all] --action [start, stop] --preset [OPTIONAL: true]`
-   --cluster = select which cluster/s to be started. E.G: `--cluster redis,kafka` or all `--cluster all`
-   --action = `start` - run the cluster up; `stop` - setdown the cluster
-   --preset = `--preset true` generates all additional values files, certificates and uuids. The output can be seen in `tml` dir. After generation process, the generated files are distributed across helm clusters.

Note: Once `--preset true` you don't need to build it again. Use just `./cluster.sh --cluster [mongodb, redis, kafka, all] --action [start, stop]`

## Screen Logs

-   `./cluster --cluster all --action start --preset true`

![Alt text](screen_logs/s2.png)

-   `./cluster --cluster all --action stop`

![Alt text](screen_logs/s2.png)

-   `Docker Desktop`

![Alt text](screen_logs/s3.png)

# K8s Cluster Setup for Kafka KRaft, MongoDB, and Redis

## Project Overview

This project provides a robust and scalable foundation for deploying essential data services within a Kubernetes (K8s) environment. It serves as a foundational "start point" for future projects requiring highly available and performant Kafka, MongoDB, and Redis clusters.

The primary goal is to offer a streamlined, declarative approach to setting up these critical components, leveraging Kubernetes' orchestration capabilities for managing stateful applications.

**This project was created with the idea to utilize the latest Apache Kafka image available and to streamline the deployment by minimizing overhead, specifically by avoiding complex sidecar and initContainer patterns.** Instead, the Kafka process itself, along with its necessary initialization logic, runs directly as the main container entrypoint.

### Built With

-   Apache Kafka (KRaft)
-   MongoDB
-   Redis
-   Kubernetes

### Prerequisites

-   A running Kubernetes cluster (e.g., minikube, kind, GKE, EKS, AKS).
-   `kubectl` installed and configured to connect to your cluster.
-   `bash` or compatible shell for running scripts.

## Quick Start (Automated Deployment)

For a rapid deployment of all clusters, use the provided `setup.sh` and `setdown.sh` scripts.

### Prerequisites (Quick Start)

-   A running Kubernetes cluster (e.g., minikube, kind, GKE, EKS, AKS).
-   `kubectl` installed and configured to connect to your cluster.
-   `bash` or compatible shell.

### Deploy All Clusters

1.  **Clone the Repository:**

2.  **Run the Setup Script:**
    This script will generate necessary ConfigMaps and apply all Kubernetes manifests for Kafka (controllers and brokers), MongoDB, and Redis.
    ```bash
    ./setup.sh
    ```
3.  **Monitor Deployment:**
    It will take some time for all pods to become `Running` and `Ready` as they perform their respective initializations (Kafka KRaft formatting, MongoDB replica set initiation, Redis cluster formation).
    ```bash
    kubectl get pods -n authentication -w
    ```
    Wait until all pods show `1/1` READY and `Running` status.

### Teardown All Clusters

To remove all deployed clusters and their associated resources (services, StatefulSets, ConfigMaps, Secrets, and Persistent Volume Claims), use the `setdown.sh` script:

1.  **Navigate to the project root:**
    ```bash
    cd AUTH_K8S
    ```
2.  **Run the Teardown Script:**
    ```bash
    ./setdown.sh
    ```
    This script will attempt to gracefully remove nodes from clusters (e.g., Redis `preStop` hook) before deleting resources and PVCs.

## Apache Kafka KRaft Cluster

The initial focus of this setup is the deployment of an Apache Kafka cluster utilizing the KRaft (Kafka Raft) consensus protocol. KRaft simplifies Kafka's architecture by removing the dependency on Apache ZooKeeper, making the cluster management more lightweight and integrated.

This section details the K8s manifest files and scripts required to bring up a production-ready Kafka KRaft cluster.

### Key Features of the Kafka KRaft Deployment

-   **ZooKeeper-less Kafka:** Leverages the KRaft protocol for metadata management, simplifying deployment and operations.
-   **Kubernetes Native:** Deploys Kafka brokers and controllers as StatefulSets, ensuring stable network identifiers and persistent storage.
-   **Dynamic Configuration:** Kafka configuration (`server.properties`) is dynamically generated within the Kafka pods at startup, leveraging environment variables and mounted configuration templates.
-   **Automated Storage Formatting:** KRaft storage formatting is automatically handled by an entrypoint script within the Kafka pods.
-   **Service Discovery:** Configures Kubernetes Headless Services for stable internal DNS resolution for Kafka brokers and controllers.
-   **Centralized Initialization Scripts:** Uses a ConfigMap to bundle and distribute crucial initialization scripts and configuration templates to the Kafka pods.

## Getting Started with Kafka KRaft

### Installation and Deployment

1.  **Generate the Kafka Initialization ConfigMap:**
    The `create_config.sh` script bundles all necessary initialization scripts (`commando.sh`, `commando_controller_members.sh`, `commando_broker_members.sh`) and Kafka property templates (`controller.properties`, `broker.properties`) into a Kubernetes ConfigMap. This ConfigMap is then mounted into your Kafka pods.

    Run the script to generate `configmap.yaml`:

    ```bash
    ./init_script/create_config.sh
    ```

    This command will create or update the `configmap.yaml` file in the current directory (`kafka-cluster/`).

2.  **Review Configuration Files (Optional but Recommended):**
    Before deploying, you may want to inspect and adjust the Kafka properties and Kubernetes manifests to suit your specific needs.

    -   `init_script/broker.properties`
    -   `init_script/controller.properties`
    -   `secret.yaml` (Contains `KAFKA_CLUSTER_ID` and `KAFKA_CONTROLLER_UUIDs`. For production, consider using a more secure method for secrets management, and generating these values dynamically or from a secure source rather than hardcoding. Note: `KAFKA_CONTROLLER_UUIDs` must be unique per controller and correspond to its node ID).

3.  **Deploy Kubernetes Resources:**
    Apply the Kubernetes manifest files in the specified order. The `authentication` namespace will be created if it doesn't exist.

    -   **Namespace (defined in `secret.yaml`):**
        ```bash
        kubectl apply -f secret.yaml
        ```
    -   **ConfigMap (generated in step 2):**
        ```bash
        kubectl apply -f configmap.yaml
        ```
    -   **Services:**
        Deploy the headless services for stable networking.
        ```bash
        kubectl apply -f controller-service.yaml
        kubectl apply -f broker-service.yaml
        ```
    -   **StatefulSets (Controllers first, then Brokers):**
        Deploy the Kafka controllers first. The `commando.sh` script within these pods will handle KRaft storage formatting and `kafka-server-start.sh`. Wait for them to be running before deploying brokers.

        ```bash
        kubectl apply -f controller-statefulset.yaml
        # Monitor controller deployment. Wait for all '3/3' pods to be Running and Ready:
        kubectl get pods -n authentication -l app=kafka-controller-node -w
        ```

        Once controllers are ready, deploy the Kafka brokers. The `commando.sh` script will also run within these pods to set up the broker role.

        ```bash
        kubectl apply -f broker-statefulset.yaml
        # Monitor broker deployment. Wait for all '3/3' pods to be Running and Ready:
        kubectl get pods -n authentication -l app=kafka-broker-node -w
        ```

### Understanding the Initialization Flow

The `commando.sh` script, which is the entrypoint for both controller and broker containers, performs the following critical steps:

1.  **Determines Role:** Checks the `KAFKA_PROCESS_ROLES` environment variable (set in the StatefulSet) to identify if it's a `controller` or `broker` pod.
2.  **Sources Member Lists:** Based on the role, it sources either `commando_controller_members.sh` or `commando_broker_members.sh`. **It is essential that these scripts define the `KAFKA_CONTROLLER_SET_MEMBERS` and `KAFKA_BROKER_SET_MEMBERS` variables correctly, mapping Kafka Node IDs to their respective DNS names within the Kubernetes cluster.**
    -   Example for `KAFKA_CONTROLLER_SET_MEMBERS` if you have 3 controllers:
        `1@kafka-controller-node-0.kafka-service-controller.authentication.svc.cluster.local:9093,2@kafka-controller-node-1.kafka-service-controller.authentication.svc.cluster.local:9093,3@kafka-controller-node-2.kafka-service-controller.authentication.svc.cluster.local:9093`
    -   Similar for `KAFKA_BROKER_SET_MEMBERS`.
3.  **Generates `server.properties`:** It dynamically generates the Kafka `server.properties` file within the pod's `/mnt/shared/config/server.properties` path by replacing placeholders in the `controller.properties` or `broker.properties` template with values derived from environment variables and the member lists.
4.  **Formats KRaft Storage:** It checks if the KRaft metadata has already been formatted (`/var/lib/kafka/data/meta.properties` exists). If not, it executes `/opt/kafka/bin/kafka-storage.sh format` using the generated `server.properties`, `KAFKA_CLUSTER_ID`, and `KAFKA_INITIAL_CONTROLLERS` (which is derived from `KAFKA_CONTROLLER_SET_MEMBERS` and `KAFKA_CONTROLLER_UUIDs`).
5.  **Starts Kafka Server:** Finally, it starts the Kafka server process using `/opt/kafka/bin/kafka-server-start.sh` with the dynamically generated configuration.

### Verifying the Deployment

-   Check the status of your pods in the `authentication` namespace:
    ```bash
    kubectl get pods -n authentication -l app=kafka-controller-node
    kubectl get pods -n authentication -l app=kafka-broker-node
    ```
    Ensure all pods are in the `Running` state and `READY` (e.g., `1/1`).
-   Check the logs of your Kafka pods for any errors and to confirm successful startup:
    ```bash
    kubectl logs <kafka-controller-node-0-pod-name> -n authentication
    kubectl logs <kafka-broker-node-0-pod-name> -n authentication
    ```
    Look for messages indicating successful Kafka startup and KRaft leader election.

## Usage

Once the Kafka KRaft cluster is running, you can connect to it from applications deployed within the same Kubernetes cluster using the service names defined in `broker-service.yaml` and the headless service DNS pattern:

-   **Kafka Broker Service Name:** `kafka-service-broker.authentication.svc.cluster.local` (for connecting applications)
-   **Individual Broker Pods (for internal use/admin):** `kafka-broker-node-<index>.kafka-service-broker.authentication.svc.cluster.local` (e.g., `kafka-broker-node-0.kafka-service-broker.authentication.svc.cluster.local:9092`)
-   **Kafka Controller Service Name:** `kafka-service-controller.authentication.svc.cluster.local` (primarily for internal Kafka communication)
-   **Individual Controller Pods:** `kafka-controller-node-<index>.kafka-service-controller.authentication.svc.cluster.local:9093`

For external access to your Kafka cluster (e.g., from outside your Kubernetes cluster), you would need to configure additional Kubernetes services like `NodePort`, `LoadBalancer`, or an Ingress Controller with appropriate routing rules and Kafka listener configurations.

## Future Work / Next Steps

This project provides the base for:

-   **MongoDB Cluster Deployment:** Integration of the `mongo-cluster` manifests for a highly available MongoDB setup.
-   **Redis Cluster Deployment:** Integration of the `redis-cluster` manifests for a high-performance Redis caching/data store.
-   **Application Integration:** Connecting client applications to these deployed data services.
-   **Monitoring and Logging:** Adding Prometheus/Grafana for monitoring Kafka, MongoDB, and Redis metrics.
-   **CI/CD Pipeline:** Automating the deployment of these clusters.

## Contributing

(Add your contribution guidelines here if you plan to accept contributions)

## License

(Specify your project's license here, e.g., MIT, Apache 2.0)

### Installation and Deployment (MongoDB)

1.  **Navigate to the MongoDB Directory:**

    ```bash
    cd AUTH_K8S/k8s/authentication/mongo-cluster
    ```

2.  **Deploy Kubernetes Resources:**
    Apply the Kubernetes manifest files in the specified order. The `authentication` namespace (defined in `secret.yaml`) will be created if it doesn't exist.
    -   **Secrets:**
        This secret holds the MongoDB keyfile for internal authentication and the root username/password.
        **Important:** The keys provided in `secret.yaml` are for demonstration purposes. **Before deploying in a production environment, you must generate a new, strong `mongo-secret-key` (e.g., using `openssl rand -base64 756`) and new, secure `mongo-db-user` and `mongo-db-password` values.**
        ```bash
        kubectl apply -f secret.yaml
        ```
    -   **ConfigMap:**
        This ConfigMap provides the `init-cluster.sh` and `lifecycle-prestop.sh` scripts, which are crucial for the automated replica set management.
        ```bash
        kubectl apply -f configmap.yaml
        ```
    -   **Headless Service:**
        This service (`mongo-service`) provides stable DNS entries for each MongoDB pod, essential for replica set discovery.
        ```bash
        kubectl apply -f service.yaml
        ```
    -   **StatefulSet:**
        Deploy the MongoDB StatefulSet. This will create the pods and their associated Persistent Volume Claims. The `init-cluster.sh` script embedded within the container's command will handle the replica set initiation and member addition automatically as pods come online.
        ```bash
        kubectl apply -f statefulset.yaml
        # Monitor pod deployment. Wait for all '3/3' pods to be Running and Ready:
        kubectl get pods -n authentication -l app=mongo-auth -w
        ```

### Understanding the MongoDB Initialization and Lifecycle

-   **`statefulset.yaml` command/args:** When a MongoDB pod starts, it first runs `mongod` in the background with `replSet auth_rs` and keyfile authentication. Once `mongod` is reachable, it executes `init-cluster.sh`.
-   **`init-cluster.sh`:**
    -   The first pod (`mongo-node-0`) will initiate the replica set (`rs.initiate()`) and create the `admin` root user.
    -   Subsequent pods (`mongo-node-1`, `mongo-node-2`, etc.) will attempt to add themselves to the existing replica set (`rs.add()`). The script includes retry logic.
-   **`lifecycle-prestop.sh`:** This script is configured as a `preStop` hook in the StatefulSet. Before a pod is terminated (e.g., during a scale-down or rolling update), this script runs to safely remove the pod from the MongoDB replica set (`rs.remove()`), preventing the replica set from entering a degraded state.

### Verifying the MongoDB Deployment

-   Check the status of your MongoDB pods in the `authentication` namespace:
    ```bash
    kubectl get pods -n authentication -l app=mongo-auth
    ```
    Ensure all pods are in the `Running` state and `READY` (e.g., `1/1`).
-   Connect to one of the MongoDB pods and verify the replica set status:

    ```bash
    # Get the name of a running MongoDB pod, e.g., mongo-node-0
    POD_NAME=$(kubectl get pods -n authentication -l app=mongo-auth -o jsonpath='{.items[0].metadata.name}')

    # Execute rs.status() from within the primary node
    kubectl exec -it $POD_NAME -n authentication -- mongosh "mongodb://${MONGO_INITDB_ROOT_USERNAME}:${MONGO_INITDB_ROOT_PASSWORD}@localhost:27017/admin" --eval "rs.status()"
    ```

    (Replace `MONGO_INITDB_ROOT_USERNAME` and `MONGO_INITDB_ROOT_PASSWORD` with the values from your secret, or use `kubectl exec -it $POD_NAME -- env | grep MONGO_INITDB_ROOT` to see them first).
    Verify that all members are listed and in the `PRIMARY` or `SECONDARY` state.

## Usage (MongoDB)

Applications within the same Kubernetes cluster can connect to the MongoDB replica set using a connection string that lists all replica set members and specifies the replica set name (`auth_rs`). The headless service ensures these internal DNS names are resolvable.

-   **Connection String Example (adjust for your application's driver):**
    ```
    mongodb://mongo-node-0.mongo-service.authentication.svc.cluster.local:27017,mongo-node-1.mongo-service.authentication.svc.cluster.local:27017,mongo-node-2.mongo-service.authentication.svc.cluster.local:27017/?replicaSet=auth_rs&authSource=admin
    ```
    Remember to use the `MONGO_INITDB_ROOT_USERNAME` and `MONGO_INITDB_ROOT_PASSWORD` defined in your `secret.yaml` for authentication.

For external access to your MongoDB cluster, you would need to configure additional Kubernetes service types (NodePort, LoadBalancer) or an Ingress controller with appropriate routing rules. This would also require careful consideration of security and network exposure.

## Security Considerations (MongoDB)

-   **Keyfile:** The `mongo-secret-key` is critical for internal replica set authentication. **Generate a strong, unique keyfile for production environments** (e.g., `openssl rand -base64 756` and encode it to base64 for the secret).
-   **Root Credentials:** The `mongo-db-user` and `mongo-db-password` in `secret.yaml` are placeholders. **Ensure you update these to strong, randomly generated credentials for any non-demo deployment.**
-   **Role-Based Access Control (RBAC):** For applications, avoid using the root user directly. Create specific users with the minimum necessary privileges (`db.createUser()` with granular roles) for each application connecting to your MongoDB.

## Installation and Deployment (Redis)

The deployment involves generating the ConfigMap with the necessary scripts, then applying the service and StatefulSet. The cluster formation is largely automated by the scripts running within the Redis pods.

1.  **Navigate to the Redis `init-scripts` Directory:**

    ```bash
    cd AUTH_K8S/k8s/authentication/redis-cluster/init-scripts
    ```

2.  **Generate the ConfigMap YAML:**
    Run the `create_config.sh` script to bundle all the Redis cluster management scripts into `configmap.yaml`. This file will be created in the parent `redis-cluster/` directory.

    ```bash
    ./create_config.sh
    ```

    Verify the `configmap.yaml` has been created in `AUTH_K8S/k8s/authentication/redis-cluster/`.

3.  **Navigate back to the `redis-cluster` Directory:**

    ```bash
    cd .. # Now you should be in AUTH_K8S/k8s/authentication/redis-cluster
    ```

4.  **Deploy Kubernetes Resources:**
    Apply the Kubernetes manifest files in the specified order. The `authentication` namespace will be used.
    -   **ConfigMap:**
        This ConfigMap (`redis-init-scripts`) provides all the custom shell scripts (`commando.sh`, `init_cluster.sh`, `prestop.sh`, etc.) to the Redis pods.
        ```bash
        kubectl apply -f configmap.yaml
        ```
    -   **Headless Service:**
        This headless service (`redis-service`) provides stable DNS entries for each Redis pod, crucial for internal cluster communication and client discovery.
        ```bash
        kubectl apply -f service.yaml
        ```
    -   **StatefulSet:**
        Deploy the Redis StatefulSet. This will create the 6 Redis pods and their associated Persistent Volume Claims.
        ```bash
        kubectl apply -f statefulset.yaml
        # Monitor pod deployment. Wait for all '6/6' pods to be Running and Ready:
        kubectl get pods -n authentication -l app=redis-node -w
        ```

### Understanding the Redis Cluster Initialization and Lifecycle

The Redis cluster's dynamic behavior is primarily driven by the scripts mounted into each container via the `redis-init-scripts` ConfigMap and executed by the `commando.sh` entrypoint.

-   **`commando.sh` Entrypoint:**
    -   This is the main command executed when a Redis container starts.
    -   It first sources all the helper scripts (e.g., `global_tools.sh`, `cluster_tools.sh`, `init_cluster.sh`).
    -   Crucially, it then calls the `init` function (from `init_cluster.sh`) in the background (`&`), allowing the Redis server (`redis-server`) to start concurrently in the foreground. This enables the Redis process to become ready while the initialization logic determines its role in the cluster.
-   **`init_cluster.sh` (`init` function):**
    -   Determines if the current pod is part of the initial cluster group or a newly scaled-up node.
    -   If it's an **initial node** (`REDIS_NODE_ID` within the initial `REPLICAS` range): It calls `init_initial_node` from `default_cluster.sh`.
    -   If it's a **scaling node** (beyond initial `REPLICAS`): It calls `init_scale_node` from `cluster_scaling.sh`.
-   **`default_cluster.sh` (`init_initial_node` and `setup_initial_cluster`):**
    -   This is responsible for the self-forming aspect of the cluster.
    -   The script waits for all initial `REPLICAS` (6 in this case) to be running and healthy.
    -   Only the **last pod** in the initial set (`redis-node-5` in a 6-node cluster) will execute the `redis-cli --cluster create` command, joining all 6 nodes and configuring them with `CLUSTER_REPLICAS` (1 replica per master). This method ensures that the cluster is created only when all initial members are available.
-   **`cluster_scaling.sh` (`init_scale_node`, `add_new_master`, `add_replica`, `slave_controller`):**
    -   This script handles operations when the StatefulSet is scaled _up_ beyond the initial replica count.
    -   It intelligently determines if a new node should join as an empty master or a replica, and adds it to the cluster using `redis-cli --cluster add-node`.
    -   The `slave_controller` specifically handles replica nodes, and if it detects that it's the last slave being added to a master's group, it triggers a `redis-cli --cluster rebalance` to ensure proper slot distribution.
-   **`prestop.sh` Lifecycle Hook:**
    -   Configured in `statefulset.yaml` as a `preStop` hook.
    -   When a Redis pod is about to be terminated (e.g., due to `kubectl delete pod`, scale-down, or rolling update), this script (`delete_current_cluster_node` from `cluster_tools.sh`) is executed.
    -   It gracefully removes the terminating node from the Redis cluster using `redis-cli --cluster del-node`, preventing the cluster from thinking the node is still alive and maintaining cluster health.
-   **`cluster_tools.sh` and `cluster_health.sh`:** These scripts provide the underlying logic for:
    -   Finding healthy nodes (`get_healthy_cluster_node_dsn`).
    -   Adding and removing nodes from the cluster.
    -   Triggering `redis-cli --cluster rebalance` and `redis-cli --cluster fix` for optimal slot distribution and recovery.
    -   Performing various health checks on the cluster state and slot distribution.
-   **`prestop.sh` Lifecycle Hook:**
    -   Configured in `statefulset.yaml` as a `preStop` hook.
    -   When a Redis pod is about to be terminated (e.g., due to `kubectl delete pod`, scale-down, or rolling update), this script is executed.
    -   Its primary function, `remove_pod_from_cluster`, ensures a graceful shutdown:
        1.  It waits for the cluster to be healthy (`operation_loop`).
        2.  **If the terminating pod is a master**, it first calls `move_all_slots_to_masters` (from `cluster_tools.sh`) to migrate all hash slots away from itself to other available masters. This prevents data unavailability during master termination.
        3.  After slot migration (or immediately if it's a replica), it calls `delete_current_cluster_node` (from `cluster_tools.sh`) to remove the node's entry from the Redis cluster topology.
        4.  Finally, it triggers a `call_rebalance` (from `cluster_tools.sh`) to ensure the cluster's slot distribution remains optimal after the node's departure.

### Verifying the Redis Cluster Deployment

-   Check the status of your Redis pods in the `authentication` namespace:

    ```bash
    kubectl get pods -n authentication -l app=redis-node
    ```

    Ensure all 6 pods are in the `Running` state and `READY` (e.g., `1/1`).

-   Connect to any one of the Redis pods and check the cluster status. This assumes you can exec into a running pod and use `redis-cli`.

    ```bash
    # Get the name of a running Redis pod, e.g., redis-node-0
    POD_NAME=$(kubectl get pods -n authentication -l app=redis-node -o jsonpath='{.items[0].metadata.name}')

    # Execute cluster info and cluster nodes commands from within the pod
    kubectl exec -it $POD_NAME -n authentication -- redis-cli -c cluster info
    kubectl exec -it $POD_NAME -n authentication -- redis-cli -c cluster nodes
    ```

    Verify that:

    -   `cluster_state` is `ok`.
    -   `cluster_known_nodes` matches your `REPLICAS` count (6).
    -   `cluster_slots_assigned` is `16384`.
    -   `cluster_slots_ok` is `16384`.
    -   `cluster_masters` is `3`.
    -   `cluster_replicas` is `3`.
    -   The `cluster nodes` output shows 3 master nodes with assigned slots and 3 replica nodes following them.

## Usage (Redis Cluster)

Applications within the same Kubernetes cluster can connect to the Redis Cluster using a Redis Cluster-aware client library. These clients typically need to be provided with the addresses of at least one or more cluster nodes, and they will automatically discover the entire cluster topology.

-   **Connection Example (depends on client library):**
    ```
    # For clients that support auto-discovery via a seed node list
    redis://redis-node-0.redis-service.authentication.svc.cluster.local:6379,redis-node-1.redis-service.authentication.svc.cluster.local:6379,redis-node-2.redis-service.authentication.svc.cluster.local:6379
    ```
    Note that while all 6 nodes are listed in the example, a Redis Cluster-aware client typically only needs one or a few to bootstrap discovery.

For external access to your Redis Cluster, you would need to configure additional Kubernetes service types (NodePort, LoadBalancer) or an Ingress controller with appropriate routing rules. This would require careful consideration of security and network exposure.

## Security Considerations (Redis)

-   **Authentication:** The provided Redis setup does not include explicit password authentication (`requirepass`). For production deployments, it is strongly recommended to enable Redis authentication. You can do this by:
    -   Adding `requirepass YOUR_STRONG_PASSWORD` to a `redis.conf` file, which you would then mount via a ConfigMap.
    -   Or by adding `--requirepass YOUR_STRONG_PASSWORD` to the `redis-server` command in `statefulset.yaml`.
    -   Then, store `YOUR_STRONG_PASSWORD` in a Kubernetes Secret and reference it in your application's deployment.
-   **Network Policies:** Implement Kubernetes Network Policies to restrict which pods can communicate with your Redis cluster, enhancing isolation and security.
-   **Persistent Volume Encryption:** For sensitive data, consider using Persistent Volumes with encryption at rest, if supported by your cloud provider or storage solution.

## Test Environment

The Kubernetes clusters were developed and tested on the following local machine specifications:

-   **Processor:** Intel Core i9-13900H (20 Cores)
-   **RAM:** 64GB DDR5 5600MHz
-   **Storage:** 4TB SSD
