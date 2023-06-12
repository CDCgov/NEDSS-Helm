# Overview

Contained are the assests needed for patient-search.

## Values

Default values for patient-search charts.

| Key | Type | Default | Description |
| -------------- | -------------- | -------------- | -------------- |
| replicaCount | int | 1 |  |
| env | string | "ai" |  |
| image | string |  |  |
| imagePullSecrets | list | [] |  |
| nameOverride | string | "" |  |
| fullnameOverride | string | "" |  |
| serviceAccount | string |  |  |
| podAnnotations | object | {} |  |
| podSecurityContext | object | {} |  |
| securityContext | object | {} |  |
| service | string |  |  |
| ingress | boolean | false |  |
| nbsExternalName | app-classic.ai-cdc-nbs.eqsandbox.com |  |  |
| resources | object | {} |  |
| autoscaling | boolean | false |  |
| nodeSelector | object | {} |  |
| tolerations | list | [] |  |
| affinity | object | {} |  |
| ingressHost | string | "app.ai-cdc-nbs.eqsandbox.com" |  |
| elasticSearchHost | string | "<http://elasticsearch.default.svc.cluster.local:9200>" |  |
| jdbc | string |  |  |
