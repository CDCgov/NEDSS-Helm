# If you are not already using Traefik

As of the NBS `7.12` release, Traefik replaces the NGINX Ingress Controller. There is more info at [Migrate from Ingress NGINX Controller to Traefik](https://doc.traefik.io/traefik/migrate/nginx-to-traefik/). For NBS7-specific migration instructions, see the [NBS 7.12-GA Traefik Installation Guide](https://nbscentral.cdc.gov/documents/883).

# Info about this Traefik Ingress Controller Helm chart

Please note that this release pins Traefik to chart [v41.0.1](https://github.com/traefik/traefik-helm-chart/releases#release-v41.0.1) (`appVersion` [v3.7.5](https://github.com/traefik/traefik-helm-chart/blob/v41.0.1/traefik/Chart.yaml#L7)).

Info about how to use this Helm chart is in the NBS 7 System Administrator Guide: https://cdcgov.github.io/NEDSS-SystemAdminGuide/docs/deploy-nbs7/initial-kubernetes-deployment/initial-kubernetes-deployment.html 

## Files

| File | Description |
|------|-------------|
| `values.yaml` | Helm values for AWS (EKS) with NLB |
| `values-azure.yaml` | Helm values for Azure (AKS) with internal load balancer |

## Deployment

Follow the aforementioned Sys Admin Guide page, except for the `helm install` command:

- include the `--version 41.0.1` flag if you wish to use that version which has been verified with NBS 7.

- include the `--set service.spec.loadBalancerIP=XX.XX.XX.XX` flag (and fill in the IP address of your load balancer for your AKS Node Pool) if you're deploying to Azure (AKS).
