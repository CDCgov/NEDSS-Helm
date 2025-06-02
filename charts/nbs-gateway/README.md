# Overview
The nbs-gateway helm chart deploys spring cloud gateway service in Kubernetes which is necessary for strangler fig routing between modern and legacy NBS.

# Requirements
Kubernetes >=1.20.0-0
Elastic Search(EFS) helm chart

# Install Chart
### Note: Please ensure image.repository, image.tag, nbsExternalName are populated before running this helm chart.  Please see the values section below for more details.  

Make sure the helm chart is on your local machine and run the following commands:

**Mac OS/Linux**

helm install nbs-gateway -f ./nbs-gateway/values.yaml nbs-gateway

**Windows**

helm install nbs-gateway -f .\nbs-gateway\values.yaml nbs-gateway

# Remove Chart
To uninstall helm chart, run the following command:

helm uninstall nbs-gateway

# Values
Values for nbs-gateway charts.

| Key | Type | Default | Description | Required |
| -------------- | -------------- | -------------- | -------------- | -------------- |
| deployment.replicas | int | 1 | Number of Pods maintained. Defaulted to 1 | N |
| env | string | "prod" | Environment information. This can be any environment string | N |
| image | string |  | nbs-gateway container image. Needs to point to the latest image from the public repository | N |
| tag | string |  | Point to release tag that needs to be installed with NBS. This is required  | N |
| gatewayService | object | Defaults to clusterIP with http port 8000, httpsport to 443 | Configures service ClusterIP with some ports | N |
| nbsExternalName | string | app-classic.example.com | Defines DNS record of the legacy application. Change this to point to legacy NBS host name | Y |
| resources | object | {} | Enable default resources. Can be used to setup resource limits if necessary | N |
| ingressHost | string | "app.example.com" | configure ingress hostname. This is not required at this point | Y |
| modernizationApiHost | string | "modernization-api.default.svc.cluster.local:8080" | Modernization Api host. Default values should work, no changes needed unless there is a change in the modernization deployment. | N |
| deduplicationApiHost | string | "deduplication-api.default.svc.cluster.local:8083" | Deduplication Api host. Default values should work, no changes needed unless there is a change in the deduplication deployment. | N |
| oidc | object | {} | Update client secret from Keycloak webui | Y |
