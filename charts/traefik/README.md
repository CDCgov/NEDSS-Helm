# Traefik Ingress Controller

Traefik v3.x replaces the NGINX Ingress Controller for NBS7 Kubernetes deployments.

[https://doc.traefik.io/traefik/migrate/nginx-to-traefik/]

## Deployment

Please note that a **specific version** (39.0.5) of the Helm chart for Traefik is required for this release, since the deployment is utilizing a pre-release image of the Traefik container. This extra `--version` tag is slated to be removed in future releases.

### AWS (EKS)

```bash
helm repo add traefik https://traefik.github.io/charts
helm repo update
helm install traefik-crds traefik/traefik-crds --namespace traefik --create-namespace
helm install traefik traefik/traefik --namespace traefik --values values.yaml --skip-crds --version 39.0.5
```

### Azure (AKS)

```bash
helm repo add traefik https://traefik.github.io/charts
helm repo update
helm install traefik-crds traefik/traefik-crds --namespace traefik --create-namespace
helm install traefik traefik/traefik --namespace traefik --values values-azure.yaml --skip-crds --version 39.0.5 --set service.spec.loadBalancerIP=XX.XX.XX.XX
```

## Files

| File | Description |
|------|-------------|
| `values.yaml` | Helm values for AWS (EKS) with NLB |
| `values-azure.yaml` | Helm values for Azure (AKS) with internal load balancer |

## Verification

```bash
kubectl get pods -n traefik
kubectl get svc -n traefik
kubectl get ingressclass
```