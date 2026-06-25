#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${1:-flask-app}"
DEPLOYMENT="${2:-flask-app}"

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl is required but not installed." >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required but not installed." >&2
  exit 1
fi

if ! command -v minikube >/dev/null 2>&1; then
  echo "minikube is required but not installed." >&2
  exit 1
fi

current_context="$(kubectl config current-context 2>/dev/null || true)"
if [[ "$current_context" != "minikube" ]]; then
  echo "Warning: current kubectl context is '$current_context' (expected 'minikube')." >&2
fi

image="$(kubectl -n "$NAMESPACE" get deployment "$DEPLOYMENT" -o jsonpath='{.spec.template.spec.containers[0].image}')"

if [[ -z "$image" ]]; then
  echo "Could not resolve image from deployment '$DEPLOYMENT' in namespace '$NAMESPACE'." >&2
  exit 1
fi

echo "Desired image: $image"
echo "Pulling image with Docker..."
docker pull "$image" >/dev/null

echo "Loading image into minikube cache..."
minikube image load "$image"

echo "Checking for image pull failures..."
failing_pods="$(kubectl -n "$NAMESPACE" get pods -l app="$DEPLOYMENT" --no-headers 2>/dev/null | awk '$3 ~ /ImagePullBackOff|ErrImagePull/ {print $1}')"
if [[ -n "$failing_pods" ]]; then
  echo "Restarting failing pods:"
  echo "$failing_pods"
  while IFS= read -r pod; do
    [[ -z "$pod" ]] && continue
    kubectl -n "$NAMESPACE" delete pod "$pod" >/dev/null
  done <<< "$failing_pods"
fi

echo "Waiting for rollout to stabilize..."
kubectl -n "$NAMESPACE" rollout status "deployment/$DEPLOYMENT" --timeout=180s

echo "Done. Deployment '$DEPLOYMENT' in namespace '$NAMESPACE' is stable with image '$image'."
