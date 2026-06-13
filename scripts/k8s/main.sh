#!/usr/bin/env bash
# k8s/main.sh — entry point for all Kubernetes operations
#
# Usage:
#   ./scripts/k8s/main.sh configure    # update kubeconfig
#   ./scripts/k8s/main.sh helm         # deploy via upstream Helm chart
#   ./scripts/k8s/main.sh all          # configure + helm

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

check_k8s_deps

usage() {
  echo ""
  echo "Usage: $0 [configure|helm|all]"
  echo ""
  echo "  configure   Point kubectl at the EKS cluster"
  echo "  helm        Deploy the upstream retail-store Helm chart"
  echo "  all         Run configure and helm in order"
  echo ""
}

case "${1:-}" in
  configure)
    bash "$SCRIPT_DIR/configure.sh"
    ;;
  helm)
    bash "$SCRIPT_DIR/helm.sh"
    ;;
  all)
    log_info "k8s all — running full Kubernetes deployment"
    echo ""
    log_info "Step 1/2 — Configure kubectl"
    bash "$SCRIPT_DIR/configure.sh"

    log_info "Step 2/2 — Deploy Helm chart"
    bash "$SCRIPT_DIR/helm.sh"

    echo ""
    log_success "Kubernetes deployment complete."
    ;;
  *)
    log_error "Unknown command: '${1:-}'"
    usage
    exit 1
    ;;
esac
