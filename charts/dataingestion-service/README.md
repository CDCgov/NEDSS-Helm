# Overview
This helm chart data-ingestion enables NBS to seamlessly ingest HL7 data from labs and other entities into the NBS system.

# Requirements
Kubernetes >=1.20.0-0


# Install Chart
### Note: Please ensure image.repository, image.tag, ingressHost, kafka cluster, efsid, jdbc and sftp are populated before running this helm chart.  Please see the values section below for more details.  

Make sure the helm chart is on your local machine and run the following commands:

**Mac OS/Linux**

helm install dataingestion-service -f ./dataingestion-service/values.yaml dataingestion-service

**Windows**

helm install dataingestion-service -f .\dataingestion-service\values.yaml dataingestion-service

# Remove Chart
To uninstall helm chart, run the following command:

helm uninstall dataingestion-service

# Values
Values for dataingestion-service charts.

| Key | Type | Default | Description | Required |
| -------------- | -------------- | -------------- | -------------- | -------------- |
| replicaCount        | int    | 1                                                                              | Number of Pods maintained. Defaulted to 1                                                                                          | N            |
| env                 | string | "prod"                                                                         | Environment information. This can be any environment string                                                                        | N            |
| image               | string |                                                                                | Data-ingestion container image. Needs to point to the latest image from the public repository                               | N            |
| tag                 | string |                                                                                | Point to release tag that needs to be installed with NBS. This is required                                                         | N            |
| nameOverride        | string | ""                                                                             | replaces name of chart on install. Not required.                                                                                   | N            |
| fullnameOverride    | string | ""                                                                             | replaces full generated name on install. Not required.                                                                             | N            |
| serviceAccount      | string |                                                                                | Used to created a service account. Not required.                                                                                   | N            |
| podAnnotations      | object | {}                                                                             | Attach metadata. Not required.                                                                                                     | N            |
| podSecurityContext  | object | {}                                                                             | Defines privilege and access control. Not Required                                                                                 | N            |
| securityContext     | object | {}                                                                             | Defines privilege and access control. Not Required                                                                                 | N            |
| service             | object | Defaults to clusterIP with port 8080, httpsport to 443 and gatewayPort to 8000 | Configures service ClusterIP with some ports                                                                                       | N            |
| ingress             | object | true with tls information                                                      | Creation of NGINX Ingress resource                                                                                                 | Y            |
| resources           | object | limits memory to 4GB                                                           | Enable default resources                                                                                                           | N            |
| autoscaling         | object | false                                                                          | Kubernetes POD autoscaler                                                                                                          | N            |
| nodeSelector        | object | {}                                                                             | Node assignment to Pod                                                                                                             | N            |
| tolerations         | list   | []                                                                             | Set Pod tolerations                                                                                                                | N            |
| affinity            | object | {}                                                                             | Define needed contraints                                                                                                           | N            |
| ingressHost         | string | "app.example.com"                                                              | configure ingress hostname                                                                                                         | Y            |
| jdbc                | Object |                                                                                | Java database connection. This is required. This needs to updated. See values.yaml for descriptions of supplied values.            | Y            |
| efsFileSystemId     | string | ""                                                                             | Populate the elastic file system ID from your AWS console. This is required.                                                       | Y            |
| kafka               | string | ""                                                                             | Deployed as MSK. Needed only if running Data Ingestion Service. Use either one of the two Kafka broker endpoints.                 | Y            |
| sftp                | object | {}                                                                             | It’s an OPTIONAL service.                                                                                                          | Y            |
