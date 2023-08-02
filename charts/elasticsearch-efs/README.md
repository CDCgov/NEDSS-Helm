# Overview

Contained are the assests needed for elasticsearch-efs.

## Values

Default values for elasticsearch-efs charts.

| Key | Type | Default | Description |
| -------------- | -------------- | -------------- | -------------- |
| replicaCount | int | 1 | Number of Pods maintained |
| image | string |  | Build image  |
| imagePullSecrets | list | [] | Secrets for build image |
| nameOverride | string | "" | replaces name of chart on install |
| fullnameOverride | string | "" | replaces full generated name on install |
| serviceAccount | string |  | Used to created a service account |
| podAnnotations | object | {} | Attach metadata |
| podSecurityContext | object | {} | Defines privilege and access control |
| securityContext | object | {} | Defines privilege and access control |
| service | string |  | Configures service ClusterIP |
| ingress | boolean | false | Creation of Ingress resource |
| resources | string |  | Enable default resources |
| autoscaling | boolean | false | Kubernetes POD autoscaler |
| nodeSelector | object | {} | Node assignment to Pod |
| tolerations | list | [] | Set Pod tolerations |
| affinity | object | {} | Define needed contraints |
| pvc | string |  | Persistent volume claim |
