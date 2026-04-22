# Strimzi Kafka Wrapper Chart

This Helm chart is an "Umbrella" or "Wrapper" chart designed to deploy a production-ready **Kafka Cluster** in **KRaft mode** using the **Strimzi Kafka Operator**. 

## 1. Architecture
This chart manages two main components:
1.  **Strimzi Operator:** Managed as a Helm dependency fetched from the official Strimzi GitHub-hosted repository.
2.  **Kafka Cluster:** Defined via local templates (`Kafka` and `KafkaNodePool` resources) to ensure persistent storage is correctly configured for cloud environments.

## 2. Prerequisites
- **Helm 3.x+**
- **Kubernetes 1.25+**

## 3. Dependency Management
The Strimzi Operator is not stored in this repository. You must fetch it before installation.

```bash
# Update dependencies based on Chart.yaml
helm dependency update strimzi/

# Standard installation
helm install kafka-release ./strimzi --namespace kafka-system --create-namespace 

# TODO
- **Storage Drivers:** - AWS: [EFS CSI Driver](https://github.com/kubernetes-sigs/aws-efs-csi-driver)
    - Azure: [Azure File CSI Driver](https://github.com/kubernetes-sigs/azurefile-csi-driver)