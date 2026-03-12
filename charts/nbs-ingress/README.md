# NBS7 Ingress Chart

Standalone Helm chart that manages all NBS7 ingress routing, decoupled from application charts.

## Why a Separate Chart?

The ingress resources were previously embedded in `modernization-api` and `dataingestion-service` Helm charts. This created a coupling problem: upgrading the ingress controller (e.g., NGINX → Traefik) required upgrading the application charts, which could pull in unwanted application changes for STLTs on older NBS7 versions.

This chart allows:
- Deploying Traefik ingress independently of NBS7 application version
- STLTs to choose their ingress provider (NGINX or Traefik) without changing application charts
- Centralized management of all routing rules in one place

## Usage

### Deploy with Traefik (default)

```bash
helm install nbs-ingress ./charts/nbs-ingress \
  --set appHost=app.example.com \
  --set dataHost=data.example.com
```

### Deploy with NGINX

```bash
helm install nbs-ingress ./charts/nbs-ingress \
  --set traefik.enabled=false \
  --set nginx.enabled=true \
  --set appHost=app.example.com \
  --set dataHost=data.example.com
```

### Switch from NGINX to Traefik

```bash
helm upgrade nbs-ingress ./charts/nbs-ingress \
  --set traefik.enabled=true \
  --set nginx.enabled=false
```

## Important Notes

- **Disable ingress in application charts** when using this chart. Set `ingress.enabled: false` in both `modernization-api` and `dataingestion-service` values.
- **Deploy this chart after application charts** so the backend services exist.
- **Only enable one provider** at a time (`nginx` or `traefik`).
- The Traefik controller itself is deployed separately via `charts/traefik/values.yaml`.