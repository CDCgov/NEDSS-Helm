# Overview

This Helm chart deploys the NBS7 Modernization API microservice to Kubernetes. Note that this microservice is comprised of two pods - `modernization-api` (core modernized NBS components), and `modernization-api-report-execution`.

# Install Chart

See the https://cdcgov.github.io/NEDSS-SystemAdminGuide/docs/deploy-nbs7/microservices-deployment/modernization-api.html page. It is optional to change/set any values in your copy of `./values.yaml` that the aforementioned page does not say to change.

# Uninstall Chart

To uninstall this Helm chart, run the following command:

`helm uninstall modernization-api`
