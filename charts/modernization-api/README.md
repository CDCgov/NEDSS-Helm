# Overview

The modernization-api helm chart deploys core modernized NBS components within Kubernetes.

# Requirements

Kubernetes >=1.20.0-0,
Elastic Search(EFS) helm chart

# Install Chart

### Note: Please ensure image.repository, image.tag, nbsExternalName, ingressHost and jdbc values are populated before running this helm chart. Ingress values need to reflect the correct host names under ingress for tls secretName and hosts. Please see the values section below for more details. Also, pass the correct connection string while running the helm chart.

Make sure the helm chart is on your local machine and run the following commands:

**Mac OS/Linux**

helm install modernization-api -f ./modernization-api/values.yaml modernization-api

**Windows**

helm install modernization-api -f .\modernization-api\values.yaml modernization-api

# Remove Chart

To uninstall helm chart, run the following command:

helm uninstall modernization-api

# Values

Values for modernization-api charts.

| Key                 | Type   | Default                                                                        | Description                                                                                                                        |
| ------------------- | ------ | ------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------- |
| replicaCount        | int    | 1                                                                              | Number of Pods maintained. Defaulted to 1                                                                                          |
| env                 | string | "prod"                                                                         | Environment information. This can be any environment string                                                                        |
| image               | string |                                                                                | Modernization-api container image. Needs to point to the latest image from the public repository                                   |
| tag                 | string |                                                                                | Point to release tag that needs to be installed with NBS. This is required                                                         |
| nameOverride        | string | ""                                                                             | replaces name of chart on install. Not required.                                                                                   |
| fullnameOverride    | string | ""                                                                             | replaces full generated name on install. Not required.                                                                             |
| serviceAccount      | string |                                                                                | Used to created a service account. Not required.                                                                                   |
| podAnnotations      | object | {}                                                                             | Attach metadata. Not required.                                                                                                     |
| podSecurityContext  | object | {}                                                                             | Defines privilege and access control. Not Required                                                                                 |
| securityContext     | object | {}                                                                             | Defines privilege and access control. Not Required                                                                                 |
| service             | object | Defaults to clusterIP with port 8080, httpsport to 443 and gatewayPort to 8000 | Configures service ClusterIP with some ports                                                                                       |
| ingress             | object | true with tls information                                                      | Creation of NGINX Ingress resource                                                                                                 |
| istioGatewayIngress | object | false                                                                          | Creation of IstioGatewayIngress                                                                                                    |
| nbsExternalName     | string | app-classic.example.com                                                        | Defines DNS record of the legacy application. Change this to point to legacy NBS host name                                         |
| resources           | object | limits memory to 4GB                                                           | Enable default resources                                                                                                           |
| autoscaling         | object | false                                                                          | Kubernetes POD autoscaler                                                                                                          |
| nodeSelector        | object | {}                                                                             | Node assignment to Pod                                                                                                             |
| tolerations         | list   | []                                                                             | Set Pod tolerations                                                                                                                |
| affinity            | object | {}                                                                             | Define needed contraints                                                                                                           |
| ingressHost         | string | "app.example.com"                                                              | configure ingress hostname                                                                                                         |
| elasticSearchHost   | string | "<http://elasticsearch.default.svc.cluster.local:9200>"                        | Elastic search host. Default values should work, no changes needed unless there is a change in the elastic search deployment name. |
| jdbc                | Object |                                                                                | Java database connection. This is required. This needs to updated. See values.yaml for descriptions of supplied values.            |
| security            | Object |                                                                                | Used to encrypt JWT, needs to match between page builder and modernization-api. See values.yaml                                 |
| ui                  | Object |                                                                                | Environment specific values that are provided to the modernization-ui                                                              |
| ui.smarty           | Object |                                                                                | Settings for the Smarty API used by the modernization-ui                                                                           |
| ui.smarty.key       | string |                                                                                | The embedded key used to authenticate the PostHog analytics client                                                                 |
| ui.analytics        | Object |                                                                                | Settings for the analytics used by the modernization-ui                                                                            |
| ui.analytics.key    | string |                                                                                | The key used to authenticate the PostHog client                                                                                    |
