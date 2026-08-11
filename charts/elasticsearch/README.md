# Overview

This Helm chart deploys Elasticsearch in Kubernetes with back-end persistent storage:

- AWS: EFS
- Azure: Private Azure Files storage, with the Azure Files CSI driver.

# Install Chart

See https://cdcgov.github.io/NEDSS-SystemAdminGuide/docs/deploy-nbs7/microservices-deployment/elasticsearch.html , and the following `Values` section provides additional info.

## Values

Default values for this chart:

| Key            | Type           | Default        | Description    | Required       |
| -------------- | -------------- | -------------- | -------------- | -------------- | 
| `replicaCount` | Integer | `1` | Number of Kubernetes Pods maintained. | Yes when `autoscaling` is not enabled |
| `image.tag` | String | See `./values.yaml` | Points to the release tag to be installed. If not specified then `appVersion` from `./Chart.yaml` is used. | N |
| `imagePullSecrets` | List | `[]` | Secrets for build image. | Yes if not pulling image from public repository |
| `nameOverride` | String | `""` | Replaces name of chart on install. | N |
| `fullnameOverride` | String | `""` | Replaces full generated name on install. | N |
| `serviceAccount` | Nested values | enabled | Used to created a service account. | N |
| `podAnnotations` | Map | `{}` | Key-value pairs to attach as metadata to the Pod. | N |
| `securityContext` | Nested values | See `./values.yaml` | 'runAsUser' is the User ID (UID) that executes the container's processes, and 'fsGroup' is the filesystem group ID (GID) to use for any volume mounted on the pod. | Y |
| `service` | Nested values | See `./values.yaml` | Configures the Kubernetes Service | Y |
| `ingress` | Nested values | disabled | Creation of Ingress resource. | N (because elastic search is an internal service) |
| `resources` | Nested values | See `./values.yaml` | Sets limits and requests for resources | N |
| `autoscaling` | Nested values | disabled | Kubernetes Pod autoscaler | `autoscaling.enabled` is always required, and the rest of the nested values are required only when this autoscaling feature is enabled. |
| `nodeSelector` | Map | `{}` | Node assignment to Pod | N |
| `tolerations` | List | `[]` | The Pod's tolerations | N |
| `affinity` | Map | `{}` | The Pod's scheduling constraints - e.g. co-locate this pod in the same node, zone, etc. as some other pod(s). | N |
| `cloudProvider` | String | aws | Set to your cloud provider | Y |
| `azure` | Nested values | See `./values.yaml` | Creates a PersistentVolumeClaim (PVC) and StorageClass for Azure | Yes when `cloudProvider` is azure, otherwise ignored |
| `pvc` | Nested values | See `./values.yaml` | Creates a PVC for AWS | Yes when `cloudProvider` is aws, otherwise ignored |
| `efsFileSystemId` | String | `""` | Creates a StorageClass for AWS | Yes when `cloudProvider` is aws, otherwise ignored |

# Uninstall Chart

To uninstall this chart, run the following command:

`helm uninstall elasticsearch`
