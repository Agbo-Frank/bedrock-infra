#!/usr/bin/env bash
# k8s/configure.sh — update kubeconfig to point kubectl at the EKS cluster
# Called by main.sh. Do not run directly.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

load_tf_outputs

log_info "Updating kubeconfig for cluster: $CLUSTER_NAME (region: $REGION)"
aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"

log_info "Verifying cluster connectivity..."
kubectl get nodes

log_success "kubectl is now configured for $CLUSTER_NAME"
