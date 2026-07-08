#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="$SCRIPT_DIR/../manifests"

MINIKUBE_PROFILE="${MINIKUBE_PROFILE:-nbs-local}"

echo "==> Removing deployed resources"
kubectl delete -f "$MANIFESTS_DIR/nedssdev.yaml" --ignore-not-found
kubectl delete -f "$MANIFESTS_DIR/kafka.yaml" --ignore-not-found
kubectl delete -f "$MANIFESTS_DIR/nedssdb.yaml" --ignore-not-found

echo "==> Stopping minikube (profile: $MINIKUBE_PROFILE)"
minikube stop --profile "$MINIKUBE_PROFILE"

echo "==> Done. Run 'minikube delete --profile $MINIKUBE_PROFILE' to fully remove the cluster."
