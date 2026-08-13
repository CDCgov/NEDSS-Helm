# Overview

This Helm chart deploys the NBS7 Modernization API microservice to Kubernetes. Note that this microservice is comprised of two pods - `modernization-api` (core modernized NBS components), and `modernization-api-report-execution`.

# Install Chart

See the https://cdcgov.github.io/NEDSS-SystemAdminGuide/docs/deploy-nbs7/microservices-deployment/modernization-api.html page, and the following `Values` section provides additional info.. It is optional to change/set any values in your copy of `./values.yaml` that the aforementioned page does not say to change.

## Values

The values for this chart:

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
| `pageBuilder`        | Nested values | disabled            | Used by the `--nbs.ui.features.pageBuilder.*` args to the `modernization-api` container. | N |
| `nbsExternalName`    | String        | n/a                 | Change this to the DNS record of the legacy NBS hostname. | Y |
| `resources`          | Nested values | See `./values.yaml` | Sets limits and requests for resources. | N |
| `autoscaling`        | Nested values | disabled            | Kubernetes Pod autoscaler. | `autoscaling.enabled` is always required, and the rest of the nested values are required only when this autoscaling feature is enabled. |
| `nodeSelector`       | Map           | `{}`                | Node assignment to Pod. | N |
| `tolerations`        | List          | `[]`                | The Pod's tolerations. | N |
| `affinity`           | Map           | `{}`                | The Pod's scheduling constraints - e.g. co-locate this pod in the same node, zone, etc. as some other pod(s). | N |
| `ingressHost`        | String        | n/a                 | See `./values.yaml` | Y |
| `timezone`           | String        | `"UTC"`             | The timezone to initialize the JVM with. | N |
| `elasticSearchHost`  | String        | See `./values.yaml` | The Elasticsearch host. Default value will work - unless there is a change in the Kubernetes deployment name from the Helm chart of the Elasticsearch NBS7 microservice. | Y |
| `jdbc`               | Nested values | n/a                 | Java database connection. | Y |
| `reportExecution`    | Nested values | n/a                 | Used primarily by the modernization-api-report-execution pod. | Y |
| `security`           | Nested values | n/a                 | Used for encryption. | Y |
| `oidc`               | Nested values | enabled             | The URL for Keycloak login authentication. | N | 
| `ui`                 | Object        | See `./values.yaml` | Environment specific values (i.e. settings and feature flags) that are provided to the modernized ui. | N |
| `probes`             | Nested values | enabled             | The readiness and liveness probes. | N |
| `spring`             | Nested values | disabled            | Whether liquibase is enabled | N |

# Uninstall Chart

To uninstall this Helm chart, run the following command:

`helm uninstall modernization-api`
