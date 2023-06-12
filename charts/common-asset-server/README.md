# Overview

Contained are the assests needed for common-asset-server.

## Values

Default values for common-asset-server charts.

| Key | Type | Default | Description |
| -------------- | -------------- | -------------- | -------------- |
| replicaCount | int | 2 |  |
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
| resources | object | {} |  |
| autoscaling | boolean | false |  |
| nodeSelector | object | {} |  |
| tolerations | list | [] |  |
| affinity | object | {} |  |
