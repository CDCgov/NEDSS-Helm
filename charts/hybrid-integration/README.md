# Overview

Contained are the assests needed for hybrid-integration.

## Values

Default values for hybrid-integration charts.

| Key | Type | Default | Description |
| -------------- | -------------- | -------------- | -------------- |
| replicaCount | int | 1 |  |
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
| nbsExternalName | sting | app-classic.ai-cdc-nbs.eqsandbox.com |  |
| resources | object | {} |  |
| autoscaling | boolean | false |  |
| nodeSelector | object | {} |  |
| tolerations | list | [] |  |
| affinity | object | {} |  |
