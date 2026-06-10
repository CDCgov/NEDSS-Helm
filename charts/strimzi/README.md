# Strimzi Kafka Wrapper Chart

This Helm chart is an "Umbrella" or "Wrapper" chart designed to deploy a production-ready **Kafka Cluster** in **KRaft mode** using the **Strimzi Kafka Operator**. 

## 1. Architecture
This chart manages two main components:
1.  **Strimzi Operator:** Managed as a Helm dependency fetched from the official Strimzi GitHub-hosted repository.
2.  **Kafka Cluster:** Defined via local templates (`Kafka` and `KafkaNodePool` resources) to ensure persistent storage is correctly configured for cloud environments.

## 2. Prerequisites
- **Helm 3.x+**
- **Kubernetes 1.25+**
- **Drivers for Kubernetes Persistent Volumes**
    - AWS EBS #documentation https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html
    - Azure Disk
## 3. Dependency Management
The Strimzi Operator is not stored in this repository. You must fetch it before installation.

```bash
# Update dependencies based on Chart.yaml
helm dependency update strimzi/

# Standard installation
helm install kafka-release ./strimzi --namespace kafka-system --create-namespace 
```

## Quick commands for reviewing Kafka topics
```
# Check Available Kafka topics
kubectl exec -it <cluster-name>-broker-0 -n <your-namespace> -- bin/kafka-topics.sh --bootstrap-server localhost:9092 --list

# Info about Kafka topic
kubectl exec -it <cluster-name>-broker-0 -n <your-namespace> -- bin/kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic <topic-name>

# Check if topic has data 
kubectl exec -it <cluster-name>-broker-0 -n <your-namespace> -- bin/kafka-get-offsets.sh --bootstrap-server localhost:9092 --topic <topic-name>

# Tail topic (note must be actively used)
kubectl exec -it <cluster-name>-broker-0 -n <your-namespace> -- bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic <topic-name> --from-beginning --max-messages 10
```