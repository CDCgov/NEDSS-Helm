# Overview

Contained are the assests needed for nifi.

## Values

Default values for nifi charts.

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
| resources | object | {} |  |
| autoscaling | boolean | false |  |
| nodeSelector | object | {} |  |
| tolerations | list | [] |  |
| affinity | object | {} |  |
| containerPort | int | 8443 |  |
| jdbcConnectionString | string | "" |  |
| singleUserCredentialsPassword | string | "" |  |
| elasticSearchHost | string | "<http://elasticsearch.default.svc.cluster.local:9200>" |  |
