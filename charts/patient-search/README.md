# Overview

Contained are the assests needed for patient-search.

## Values

Default values for patient-search charts.

| Key | Type | Default | Description |
| -------------- | -------------- | -------------- | -------------- |
| replicaCount | int | 1 | Number of Pods maintained |
| env | string | "ai" | Environment information |
| image | string |  | Build image |
| imagePullSecrets | list | [] | Secrets for build image |
| nameOverride | string | "" | replaces name of chart on install |
| fullnameOverride | string | "" | replaces full generated name on install |
| serviceAccount | string |  | Used to created a service account |
| podAnnotations | object | {} | Attach metadata |
| podSecurityContext | object | {} | Defines privilege and access control |
| securityContext | object | {} | Defines privilege and access control |
| service | string |  | Configures service ClusterIP |
| ingress | boolean | true | Creation of Ingress resource |
| nbsExternalName | app-classic.ai-cdc-nbs.eqsandbox.com |  | Defines DNS record |
| resources | object | {} | Enable default resources |
| autoscaling | boolean | false | Pod autoscaler |
| nodeSelector | object | {} | Node assignment to Pod |
| tolerations | list | [] | Set Pod tolerations |
| affinity | object | {} | Define needed contraints |
| ingressHost | string | "app.ai-cdc-nbs.eqsandbox.com" | configure ingress hostname |
| elasticSearchHost | string | "<http://elasticsearch.default.svc.cluster.local:9200>" | Elastic search host |
| jdbc | string |  | Java database connection |
