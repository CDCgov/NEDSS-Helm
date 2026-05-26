# Overview

This Helm chart is for `dataingestion-service`, which enables NBS to seamlessly ingest HL7 data from labs and other entities into the NBS system.

# Requirements

See https://cdcgov.github.io/NEDSS-SystemAdminGuide/docs/deploy-nbs7/quickstart.html#environment-requirements and https://cdcgov.github.io/NEDSS-SystemAdminGuide/docs/deploy-nbs7/prerequisites.html#required-tools and https://cdcgov.github.io/NEDSS-SystemAdminGuide/docs/deploy-nbs7/prerequisites.html#software-versions .

# Install Chart

See https://cdcgov.github.io/NEDSS-SystemAdminGuide/docs/deploy-nbs7/data-ingestion/data-ingestion.html .

# Uninstall Chart

To uninstall this Helm chart, run the following command:

`helm uninstall dataingestion-service`

# Values

Values for dataingestion-service charts.

| Key                 | Type   | Default                                                                        | Description                                                                                                                        | Required |
| --------------      | -------------- | -------------- | -------------- | -------------- |
| replicaCount        | int    | 1                                                                              | Number of Pods maintained. Defaulted to 1                                                                                          | N            |
| image               | string |                                                                                | Data-ingestion container image. Needs to point to the latest image from the public repository                                      | N            |
| tag                 | string |                                                                                | Point to release tag that needs to be installed with NBS. This is required                                                         | N            |
| nameOverride        | string | ""                                                                             | replaces name of chart on install. Not required.                                                                                   | N            |
| fullnameOverride    | string | ""                                                                             | replaces full generated name on install. Not required.                                                                             | N            |
| serviceAccount      | string |                                                                                | Used to created a service account. Not required.                                                                                   | N            |
| podAnnotations      | object | {}                                                                             | Attach metadata. Not required.                                                                                                     | N            |
| podSecurityContext  | object | {}                                                                             | Defines privilege and access control. Not Required                                                                                 | N            |
| securityContext     | object | {}                                                                             | Defines privilege and access control. Not Required                                                                                 | N            |
| service             | object | Defaults to clusterIP with port 8080, httpsport to 443 and gatewayPort to 8000 | Configures service ClusterIP with some ports                                                                                       | N            |
| ingress             | object | true                                                                           | Creation of NGINX Ingress resource                                                                                                 | Y            |
| resources           | object |                                                                                | Server resource requests and limits                                                                                                | N            |
| autoscaling         | object | false                                                                          | Kubernetes POD autoscaler                                                                                                          | N            |
| nodeSelector        | object | {}                                                                             | Node assignment to Pod                                                                                                             | N            |
| tolerations         | list   | []                                                                             | Set Pod tolerations                                                                                                                | N            |
| affinity            | object | {}                                                                             | Define needed contraints                                                                                                           | N            |
| ingressHost         | string | "app.example.com"                                                              | configure ingress hostname                                                                                                         | Y            |
| jdbc                | Object |                                                                                | Java database connection. This is required. This needs to updated. See values.yaml for descriptions of supplied values.            | Y            |
| efsFileSystemId     | string | ""                                                                             | Populate the elastic file system ID from your AWS console. This is required for AWS.                                               | Y            |
| kafka               | string | ""                                                                             | Deployed as MSK. Needed only if running Data Ingestion Service. Use either one of the two Kafka broker endpoints.                  | Y            |
| sftp                | object | {}                                                                             | It’s an OPTIONAL service.                                                                                                          | Y            |
