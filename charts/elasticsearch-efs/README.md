# Overview

Contained are the assests needed for elasticsearch-efs.

## Values

Default values for elasticsearch-efs charts.

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
| securityContext | string |  |  |
| service | string |  |  |
| ingress | boolean | false |  |
| resources | string |  |  |
| autoscaling | boolean | false |  |
| nodeSelector | object | {} |  |
| tolerations | list | [] |  |
| affinity | object | {} |  |
| pvc | string |  |  |
