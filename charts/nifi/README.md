# Overview

This Helm chart deploys NiFi in Kubernetes.

The [Elasticsearch](https://cdcgov.github.io/NEDSS-SystemAdminGuide/docs/deploy-nbs7/microservices-deployment/elasticsearch.html) and [Modernization API](https://cdcgov.github.io/NEDSS-SystemAdminGuide/docs/deploy-nbs7/microservices-deployment/modernization-api.html) NBS 7 microservices must already be installed/deployed before installing this chart/microservice.

# Install Chart

See https://cdcgov.github.io/NEDSS-SystemAdminGuide/docs/deploy-nbs7/microservices-deployment/nifi.html .

# Uninstall Chart

To uninstall this chart, run the following command:

`helm uninstall nifi`

## Values

Default values for this chart:

| Key                  | Type          | Default             | Description | Required |
| -------------------- | ------------- | ------------------- | -------------------------------------- | --- |
| `replicaCount`       | Integer       | `1`                 | Number of Kubernetes Pods maintained. | Yes when `autoscaling` is not enabled. |
| `imagePullSecrets`   | List          | `[]`                | Secrets for build image. | Yes if not pulling image from public repository. |
| `nameOverride`       | String        | `""`                | Replaces name of chart on install. | N |
| `fullnameOverride`   | String        | `""`                | Replaces full generated name on install. | N |
| `serviceAccount`     | Nested values | enabled             | Used to created a service account. | N |
| `podAnnotations`     | Map           | `{}`                | Key-value pairs to attach as metadata to the Pod. | N |
| `podSecurityContext` | object        | `{}`                | Defines privilege and access control. | Y |
| `securityContext`    | Nested values | See `./values.yaml` | Defines privilege and access control. | Y |
| `service`            | Nested values | See `./values.yaml` | Configures the Kubernetes Service. | Y |
| `ingress`            | Nested values | disabled            | Creation of Ingress resource with NGINX. | `ingress.enabled` is always required, and the rest of the nested values are required only when this ingress feature is enabled. |
| `resources`          | Nested values | See `./values.yaml` | Sets limits and requests for resources. | N |
| `autoscaling`        | Nested values | disabled            | Kubernetes Pod autoscaler. | `autoscaling.enabled` is always required, and the rest of the nested values are required only when this autoscaling feature is enabled. |
| `nodeSelector`       | Map           | `{}`                | Node assignment to Pod. | N |
| `tolerations`        | List          | `[]`                | The Pod's tolerations. | N |
| `affinity`           | Map           | `{}`                | The Pod's scheduling constraints - e.g. co-locate this pod in the same node, zone, etc. as some other pod(s). | N |
| `containerPort`      | Integer       | See `./values.yaml` | Set container port | Y |
| `cloudProvider`      | String        | aws                 | Set to your cloud provider | Y |
| `azure`              | Nested values | See `./values.yaml` | Creates a PersistentVolumeClaim (PVC) and StorageClass for Azure | Yes when `cloudProvider` is azure, otherwise ignored |
| `pvc`                | Nested values | See `./values.yaml` | Creates a PVC for AWS | Yes when `cloudProvider` is aws, otherwise ignored |
| `efsFileSystemId`    | String        | n/a                 | Creates a StorageClass for AWS | Yes when `cloudProvider` is aws, otherwise ignored |
| `jvmheap`            | object        | See `./values.yaml` | Sets the jvm heap memory for NIFI | Y |
| `jdbcConnectionString` | String      | n/a                 | Java database connection string. | Y |
| `elasticSearchHost`  | String        | See `./values.yaml` | The Elasticsearch host. Default value will work - unless there is a change in the Kubernetes deployment name from the Helm chart of the Elasticsearch NBS7 microservice. | Y |
| `singleUserCredentialsUsername` | String | n/a             | Set the NIFI username for NIFI UI | Y |
| `singleUserCredentialsPassword` | String | n/a             | Set the NIFI password for NIFI UI | Y |
| `nifiSensitivePropsKey` | String     | n/a                 | NiFi uses this to derive an encryption key for sensitive values that it stores internally.| Y |
