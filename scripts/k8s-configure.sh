#!/usr/bin/env bash
# k8s-configure.sh — update kubeconfig to point kubectl at the EKS cluster
# Usage: ./scripts/k8s-configure.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

check_deps
load_tf_outputs

log_info "Updating kubeconfig for cluster: $CLUSTER_NAME (region: $REGION)"
aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"

log_info "Verifying cluster connectivity..."
kubectl get nodes

log_success "kubectl is now configured for $CLUSTER_NAME"
log_info "Next step: ./scripts/k8s-manifests.sh"
