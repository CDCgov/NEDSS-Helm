#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="$SCRIPT_DIR/../manifests"

MINIKUBE_CPUS="${MINIKUBE_CPUS:-2}"
MINIKUBE_MEMORY="${MINIKUBE_MEMORY:-8g}"
MINIKUBE_PROFILE="${MINIKUBE_PROFILE:-nbs-local}"

echo "==> Starting minikube (profile: $MINIKUBE_PROFILE)"
minikube start \
  --profile "$MINIKUBE_PROFILE" \
  --cpus "$MINIKUBE_CPUS" \
  --memory "$MINIKUBE_MEMORY" \
  --driver docker

echo "==> Enabling ingress addon"
minikube addons enable ingress --profile "$MINIKUBE_PROFILE"

echo "==> Deploying nedssdb (SQL Server)"
kubectl apply -f "$MANIFESTS_DIR/nedssdb.yaml"

echo "==> Deploying kafka (KRaft mode)"
kubectl apply -f "$MANIFESTS_DIR/kafka.yaml"

echo "==> Waiting for nedssdb to be ready (this can take 1-2 minutes)..."
kubectl rollout status deployment/nbs-mssql --timeout=180s

echo "==> Deploying nedssdev (WildFly)"
kubectl apply -f "$MANIFESTS_DIR/nedssdev.yaml"

echo ""
echo "==> All services deployed."
echo "    nedssdev takes a few minutes to reach ready state."
echo "    Monitor with: kubectl get pods -w"
echo ""
echo "┌──────────────────────────────────────────────────────────────────┐"
echo "│  In-cluster connection details (use these in helm chart values)  │"
echo "├───────────┬──────────────────────────────────────────────────────┤"
echo "│  nedssdb  │  host:      nbs-mssql:1433                           │"
echo "│  kafka    │  bootstrap: kafka:29092    (INTERNAL listener)       │"
echo "└───────────┴──────────────────────────────────────────────────────┘"
echo ""
echo "==> To connect from your laptop, use port-forward:"
echo "    kubectl port-forward svc/nbs-mssql 1433:1433   # SQL Server -> localhost:1433"
echo "    kubectl port-forward svc/kafka     9092:9092   # Kafka      -> localhost:9092"
echo "    kubectl port-forward svc/nedssdev  7001:7001   # NBS UI     -> http://localhost:7001/nbs/login"
