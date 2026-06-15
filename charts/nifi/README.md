# Overview

This helm chart (nifi) deploys Apache NIFI in Kubernetes with NBS configuration.

# Requirements

Kubernetes >=1.20.0-0
Elastic Search
Modernization API

# Install Chart
**Note: Please ensure image.repository, image.tag, tls.secretName, tls.hosts[1], hosts.host, jdbcConnectionString, singleUserCrentialsPassword, proxy-redirect-to under annotations values are populated before running this helm chart. Please see Values section below for more details.**
Make sure the helm chart is on your local machine and run the following commands:

**Mac OS/Linux**

helm install nifi -f ./nifi/values.yaml nifi

**Windows**

helm install nifi -f .\nifi\values.yaml nifi

# Remove Chart
To uninstall helm chart, run the following command:

helm uninstall nifi

## Values

Default values for nifi charts.

| Key | Type | Default | Description | Required |
| -------------- | -------------- | -------------- | -------------- | -------------- |
| replicaCount | int | 1 | Number of Pods maintained. Defaulted to 1 | N |
| image | string |  |  Nifi container image. Needs to point to the latest image from the public repository  | N |
| imagePullSecrets | string |  | Secrets for build image. Not required if pulling from public repository  | N |
| tag | string |  | Point to release tag that needs to be installed with NBS. This is required  | N |
| nameOverride | string | "" | replaces name of chart on install | N |
| fullnameOverride | string | "" | replaces full generated name on install | N |
| serviceAccount | string |  | Used to created a service account. Not required. | N |
| podAnnotations | object | {} | Attach metadata. Not required. | N |
| podSecurityContext | object | {} | Defines privilege and access control. Not Required | N |
| securityContext | object | runAsUser: 1000 fsGroup: 1000 | Defines privilege and access control. The default security context defines the user permissions required to run the elastic search service. | N |
| service | object | By default clusterIP service with ports 8443 | Configures service ClusterIP | N |
| ingress | boolean | true | Creation of Ingress resource with NGINX. Populate the correct annotations for proxy-redirect-to, tls, hosts |
| resources | object | limits memory to 6GB | Enable default resources | N |
| jvmheap | object | Sets the jvm heap memory for NIFI | set to 4GB init and max size | N |
| autoscaling | object | false | Kubernetes POD autoscaler | N |
| nodeSelector | object | {} | Node assignment to Pod | N |
| tolerations | list | [] | Set Pod tolerations | N |
| affinity | object | {} | Define needed constraints | N |
| containerPort | int | 8443 | Set container port | N |
| jdbcConnectionString | string | "" | Java database connection. Please populate the correct NBS_ODSE database connection string with credentials.  See values.yaml for descriptions of supplied values. | Y |
| elasticSearchHost | string | "http://elasticsearch.default.svc.cluster.local:9200" | Elastic search host | N |
| efsFileSystemId | string | "" | EFS ID | Y |
| storageRequest | string | "50Gi" | Storage size of NiFi Stage,Database_Repository,Flowfile_Repository,Content_Repository,Provenance_Repository and Logs directories | N |
| singleUserCredentialsUsername | string | "" | Set the NIFI username for NIFI UI | Y |
| singleUserCredentialsPassword | string | "" | Set the NIFI password for NIFI UI | Y |
| nifiSensitivePropsKey | string | "" | Set the NIFI Sensitive Props Key. Specifies the source string used to derive an encryption key.| Y |