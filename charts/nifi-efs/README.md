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

| Key | Type | Default | Description |
| -------------- | -------------- | -------------- | -------------- |
| replicaCount | int | 1 | Number of Pods maintained. Defaulted to 1 |
| image | string |  |  Nifi container image. Needs to point to the latest image from the public repository  |
| imagePullSecrets | string |  | Secrets for build image. Not required if pulling from public repository  |
| tag | string |  | Point to release tag that needs to be installed with NBS. This is required  |
| nameOverride | string | "" | replaces name of chart on install |
| fullnameOverride | string | "" | replaces full generated name on install |
| serviceAccount | string |  | Used to created a service account. Not required. |
| podAnnotations | object | {} | Attach metadata. Not required. |
| podSecurityContext | object | {} | Defines privilege and access control. Not Required |
| securityContext | object | runAsUser: 1000 fsGroup: 1000 | Defines privilege and access control. The default security context defines the user permissions required to run the elastic search service. |
| service | object | By default clusterIP service with ports 8443 | Configures service ClusterIP |
| ingress | boolean | true | Creation of Ingress resource with NGINX. Populate the correct annotations for proxy-redirect-to, tls, hosts |
| resources | object | limits memory to 6GB | Enable default resources |
| jvmheap | object | Sets the jvm heap memory for NIFI | set to 4GB init and max size |
| autoscaling | object | false | Kubernetes POD autoscaler |
| nodeSelector | object | {} | Node assignment to Pod |
| tolerations | list | [] | Set Pod tolerations |
| affinity | object | {} | Define needed constraints |
| containerPort | int | 8443 | Set container port |
| jdbcConnectionString | string | "" | Java database connection. Please populate the correct NBS_ODSE database connection string with credentials.  See values.yaml for descriptions of supplied values. |
| elasticSearchHost | string | "http://elasticsearch.default.svc.cluster.local:9200" | Elastic search host |
| efsFileSystemId | string | "" | EFS ID |
| storageRequest | string | "50Gi" | Storage size of NiFi Stage,Database_Repository,Flowfile_Repository,Content_Repository,Provenance_Repository and Logs directories |
| singleUserCredentialsUsername | string | "" | Set the NIFI username for NIFI UI |
| singleUserCredentialsPassword | string | "" | Set the NIFI password for NIFI UI |
| nifiSensitivePropsKey | string | "" | Set the NIFI Sensitive Props Key. Specifies the source string used to derive an encryption key.|