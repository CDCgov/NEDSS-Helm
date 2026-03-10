# Traefik Ingress Controller

Traefik v3.x replaces the NGINX Ingress Controller for NBS7 Kubernetes deployments.

[https://doc.traefik.io/traefik/migrate/nginx-to-traefik/]

## Deployment

### AWS (EKS)

```bash
helm repo add traefik https://traefik.github.io/charts
helm repo update
helm install traefik-crds traefik/traefik-crds --namespace traefik --create-namespace
helm install traefik traefik/traefik --namespace traefik --values values.yaml --skip-crds
```

### Azure (AKS)

```bash
helm repo add traefik https://traefik.github.io/charts
helm repo update
helm install traefik-crds traefik/traefik-crds --namespace traefik --create-namespace
helm install traefik traefik/traefik --namespace traefik --values values-azure.yaml --skip-crds --set service.spec.loadBalancerIP=XX.XX.XX.XX
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