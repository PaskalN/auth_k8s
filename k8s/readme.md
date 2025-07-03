Kubectl:

// ----------------- PODS ------------------------------
kubectl get pods - return all pods
kubectl get pods -n <NAMESPACE> - return all pods from namespace

kubectl delete pods --all - delete all pods
kubectl delete pods --all -n <NAMESPACE> - delete all pods from the namespace

kubectl delete pod <POD_NAME> - delete a pod with a name
kubectl delete pod <POD_NAME> -n <NAMESPACE> - delete a pod with a name from a namespace

kubectl describe pod <NAMESPACE> - returns the metadata for the pod
kubectl describe pod <NAMESPACE> -n <NAMESPACE> - returns the metadata for the pod in the namespace

kubectl apply -f <FILE_NAME> - creates pod

// ----------------- REPLICA SET ---------------------------

kubectl get replicaset - returns the list of all replicaset
kubectl get replicaset -n <NAMESPACE> - returns the list of all replicaset from the namespace

kubectl get replicaset <REPLICA_SET_NAME> - returns the details about the replicaset
kubectl get replicaset <REPLICA_SET_NAME> -n <NAMESPACE> - returns the details about the replicaset in the namespace

kubectl delete replicaset <REPLICA_SET_NAME> - deletes the replicaset and the pods inside
kubectl delete replicaset <REPLICA_SET_NAME> -n <NAMESPACE> - deletes the replicaset and the pods inside from the namespace

kubectl describe replicaset <REPLICA_SET_NAME> - returns the metadata
kubectl describe replicaset <REPLICA_SET_NAME> -n <NAMESPACE> - returns the metadata from the namespace

kubectl apply -f <FILE_NAME> - creates replicaset

// ----------------- NAMESPACE ---------------------------
kubectl get namespaces - returns a list of all namespaces in the cluster
kubectl describe namespace <NAMESPACE_NAME> - Shows detailed info about a specific namespace.
kubectl delete namespace <NAMESPACE_NAME> - Delete (remove) a namespace

kubectl create namespace <NAMESPACE_NAME> - create namespace
or use yaml file

```
apiVersion: v1
kind: Namespace
metadata:
  name: <NAMESPACE_NAME>
```

and then
kubectl apply -f <NAMESPACE_FILE_NAME>
