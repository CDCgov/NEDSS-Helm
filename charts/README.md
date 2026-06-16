# Overview

Contained are all current helm charts needed to deploy micoservices related to the NBS application.

## Charts

The following helm charts are contained within this repository:

1. [patient-search](charts/patient-search) - deploys the modern NBS container
1. [elasticsearch](charts/elasticsearch) - deploys elasticsearch opensource project
1. [nifi](charts/nifi) - deploys NiFi opensource project
1. [nginx-ingress](charts/nginx-ingress) - deploys nginx-ingress controller opensource project
1. [hybrid-integration](charts/hybrid-integration) - deploys nginx container for routing application traffic5
1. [kafka](charts/kafka) - (local or on-prem only) deploys kafka service
1. [common-asset-server](charts/common-asset-server) - (currrently not in use) deploys resources in a common space to be used by existing microservices
