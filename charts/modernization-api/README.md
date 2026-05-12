# Overview

The `modernization-api` Helm chart deploys core modernized NBS components within Kubernetes.

# Requirements

Per https://cdcgov.github.io/NEDSS-SystemAdminGuide/docs/deploy-nbs7/quickstart.html#deploy-nbs-7-microservices-helm , the `elasticsearch-efs` chart must be installed before this chart.

Also see https://cdcgov.github.io/NEDSS-SystemAdminGuide/docs/deploy-nbs7/prerequisites.html#software-versions .

# Install Chart

NOTE: Before installing this Helm chart, please:

- ensure the `image.tag` value is set to the version of this microservice that you wish to deploy.

- search for "EXAMPLE" in `./values.yaml` and fill in those values. (See the Values section below for more details.)

See https://cdcgov.github.io/NEDSS-SystemAdminGuide/docs/deploy-nbs7/microservices-deployment/modernization-api.html for the rest of the info for how to install this chart.

# Uninstall Chart

To uninstall this Helm chart, run the following command:

`helm uninstall modernization-api`

# Values

Values for `modernization-api` charts.

| Key                 | Type   | Default                                                                        | Description                                                                                                                        | Required |
| ------------------- | ------ | ------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------- | ------------ |
| replicaCount        | int    | 1                                                                              | Number of Pods maintained. Defaulted to 1                                                                                          | N            |
| image               | string |                                                                                | Modernization-api container image. Needs to point to the latest image from the public repository                                   | N            |
| tag                 | string |                                                                                | Point to release tag that needs to be installed with NBS. This is required                                                         | N            |
| nameOverride        | string | ""                                                                             | replaces name of chart on install. Not required.                                                                                   | N            |
| fullnameOverride    | string | ""                                                                             | replaces full generated name on install. Not required.                                                                             | N            |
| serviceAccount      | string |                                                                                | Used to created a service account. Not required.                                                                                   | N            |
| podAnnotations      | object | {}                                                                             | Attach metadata. Not required.                                                                                                     | N            |
| podSecurityContext  | object | {}                                                                             | Defines privilege and access control. Not Required                                                                                 | N            |
| securityContext     | object | {}                                                                             | Defines privilege and access control. Not Required                                                                                 | N            |
| service             | object | Defaults to clusterIP with port 8080, httpsport to 443 and gatewayPort to 8000 | Configures service ClusterIP with some ports                                                                                       | N            |
| nbsExternalName     | string | app-classic.example.com                                                        | Defines DNS record of the legacy application. Change this to point to legacy NBS host name                                         | N            |
| resources           | object | limits memory to 4GB                                                           | Enable default resources                                                                                                           | N            |
| autoscaling         | object | false                                                                          | Kubernetes POD autoscaler                                                                                                          | N            |
| nodeSelector        | object | {}                                                                             | Node assignment to Pod                                                                                                             | N            |
| tolerations         | list   | []                                                                             | Set Pod tolerations                                                                                                                | N            |
| affinity            | object | {}                                                                             | Define needed contraints                                                                                                           | N            |
| ingressHost         | string | "app.example.com"                                                              | configure ingress hostname                                                                                                         | N            |
| elasticSearchHost   | string | "<http://elasticsearch.default.svc.cluster.local:9200>"                        | Elastic search host. Default values should work, no changes needed unless there is a change in the elastic search deployment name. | N            |
| jdbc                | Object |                                                                                | Java database connection. This is required. This needs to updated. See values.yaml for descriptions of supplied values.            | Y            |
| security            | Object |                                                                                | Used to encrypt JWT. See values.yaml                                                                                               | Y            |
| ui                  | Object |                                                                                | Environment specific values that are provided to the modernization-ui                                                              | N            |
| ui.smarty           | Object |                                                                                | Settings for the Smarty API used by the modernization-ui                                                                           | N            |
| ui.smarty.key       | string |                                                                                | The embedded key used to authenticate the PostHog analytics client                                                                 | N            |
| ui.analytics        | Object |                                                                                | Settings for the analytics used by the modernization-ui                                                                            | N            |
| ui.analytics.key    | string |                                                                                | The key used to authenticate the PostHog client                                                                                    | N            |
