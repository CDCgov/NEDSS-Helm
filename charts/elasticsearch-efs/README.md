# Overview
This helm chart (elasticsearch-efs) deploys elastic search in Kubernetes with AWS EFS back-end.

# Requirements
Kubernetes >=1.20.0-0
AWS EFS

# Install Chart
**Note: Please ensure image.repository, image.tag, and efsFileSystemId values are populated before running this helm chart. Please see Values section below for more details.**
Make sure the helm chart is on your local machine and run the following commands:

**Mac OS/Linux**

helm install elasticsearch -f ./elasticsearch-efs/values.yaml elasticsearch

**Windows**

helm install elasticsearch -f .\elasticsearch-efs\values.yaml elasticsearch

# Remove Chart
To uninstall helm chart, run the following command:

helm uninstall elasticsearch

## Values

Default values for elasticsearch-efs charts.

| Key | Type | Default | Description | Required |
| -------------- | -------------- | -------------- | -------------- | -------------- | 
| replicaCount | int | 1 | Number of Pods maintained. Defaulted to 1 | N |
| image | string |  |  Elastic search container image. Needs to point to the latest image from the public repository  | N |
| imagePullSecrets | string |  | Secrets for build image. Not required if pulling from public repository  | N |
| tag | string |  | Point to release tag that needs to be installed with NBS. This is required  | N |
| nameOverride | string | "" | replaces name of chart on install. Not required. | N |
| fullnameOverride | string | "" | replaces full generated name on install. Not required. | N |
| serviceAccount | string |  | Used to created a service account. Not required. | N |
| podAnnotations | object | {} | Attach metadata. Not required. | N |
| podSecurityContext | object | {} | Defines privilege and access control. Not Required | N |
| securityContext | object | runAsUser: 1000 fsGroup: 1000 | Defines privilege and access control. The default security context defines the user permissions required to run the elastic search service. | N |
| service | object | By default clusterIP service with ports 9200 and 9300 is configured | Configures service ClusterIP | N |
| ingress | boolean | false | Creation of Ingress resource. Not required since elastic search is an internal service. | N |
| resources | object | limits memory to 6GB | Enable default resources | N |
| autoscaling | object | false | Kubernetes POD autoscaler | N |
| nodeSelector | object | {} | Node assignment to Pod | N |
| tolerations | list | [] | Set Pod tolerations | N |
| affinity | object | {} | Define needed contraints | N |
| pvc | object | Defaulted to 100GB | Persistent volume claim | N |
| efsFileSystemId | string | "" | Populate the elastic file system ID from your AWS console. This is required. | Y |
