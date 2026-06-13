#!/usr/bin/env bash
# k8s/helm.sh — deploy the upstream retail-store Helm chart
# Called by main.sh. Do not run directly.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

NAMESPACE="retail-app"
RELEASE="retail-app"

# Remove leftover kubectl-managed resources so Helm can install cleanly.
if ! helm status "$RELEASE" -n "$NAMESPACE" &>/dev/null; then
  if kubectl get namespace "$NAMESPACE" &>/dev/null; then
    log_warn "Namespace '$NAMESPACE' exists but Helm release '$RELEASE' does not."
    log_warn "Removing namespace (old kubectl manifests) before Helm install..."
    kubectl delete namespace "$NAMESPACE" --wait=true --timeout=180s
  fi

  # Cluster-scoped resources are not removed when the namespace is deleted.
  for resource in clusterrolebinding/bedrock-dev-view-binding; do
    if kubectl get "$resource" &>/dev/null; then
      log_warn "Removing leftover cluster resource: $resource"
      kubectl delete "$resource" --ignore-not-found
    fi
  done
fi

log_info "Updating Helm chart dependencies..."
helm dependency update "$HELM_DIR"

log_info "Generating Helm values from Terraform outputs and Secrets Manager..."
generate_helm_values

log_info "Deploying Helm release: $RELEASE"
helm upgrade --install "$RELEASE" "$HELM_DIR" \
  -f "$HELM_VALUES" \
  -f "$HELM_VALUES_GENERATED" \
  -n "$NAMESPACE" \
  --create-namespace

echo ""
log_success "Helm release deployed."
kubectl get all -n "$NAMESPACE"
echo ""
log_info "ALB address (appears after ~2 minutes):"
kubectl get ingress -n "$NAMESPACE"
