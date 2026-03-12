# NBS6 Ingress Chart

Standalone Helm chart for NBS6 (Classic/WildFly) ingress routing, decoupled from the `nbs6` application chart.

## Overview

This chart is for CDC and Montana environments that run NBS6 in a container alongside NBS7. It manages the ingress routing for the `app-classic` hostname independently of the NBS6 application chart version.

## Usage

### Deploy with Traefik (default)

```bash
helm install nbs6-ingress ./charts/nbs6-ingress \
  --set host=app-classic.example.com \
  --set serviceName=nbs6-service
```

### Deploy with NGINX

```bash
helm install nbs6-ingress ./charts/nbs6-ingress \
  --set traefik.enabled=false \
  --set nginx.enabled=true \
  --set host=app-classic.example.com \
  --set serviceName=nbs6-service
```

## Important Notes

- The `serviceName` must match the NBS6 Helm release service name (`<release-name>-service`)
- The NBS6 service exposes port 443 (HTTPS) which maps to WildFly on targetPort 7001
- Disable `ingress.enabled` in the NBS6 application chart when using this chart
- NBS6 has its own middleware CRDs (`nbs6-custom-headers`, `nbs6-cached-headers`) separate from the NBS7 `nbs-ingress` chart middlewares