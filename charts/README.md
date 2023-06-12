# Overview

Contained are all current helm charts needed to deploy micoservices related to the NBS application.

## Charts

The following helm charts are contained within this repository:

1. [patient-search](charts/patient-search) - deploys the modern NBS container
2. [elasticsearch](charts/elasticsearch) - deploys elasticsearch opensource project
3. [elasticsearch-efs](charts/elasticsearch-efs) - deploys eleasticsearch efs service
4. [nifi](charts/nife) - deploys NiFi opensource project
5. [nginx-ingress](charts/nginx-ingress) - deploys nginx-ingress controller opensource project
6. [hybrid-integration](charts/hybrid-integration) - deploys nginx container for routing application traffic5
7. [kafka](charts/kafka) - (local or on-prem only) deploys kafka service
8. [common-asset-server](charts/common-asset-server) - (currrently not in use) deploys resources in a common space to be used by existing microservices
