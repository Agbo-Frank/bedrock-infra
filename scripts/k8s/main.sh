#!/usr/bin/env bash
# k8s/main.sh — entry point for all Kubernetes operations
#
# Usage:
#   ./scripts/k8s/main.sh configure    # update kubeconfig
#   ./scripts/k8s/main.sh manifests    # apply all manifests
#   ./scripts/k8s/main.sh secrets      # create K8s secrets from Secrets Manager
#   ./scripts/k8s/main.sh configmaps   # patch ConfigMaps with live RDS endpoints
#   ./scripts/k8s/main.sh all          # run all steps in order (full k8s deploy)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

check_k8s_deps

usage() {
  echo ""
  echo "Usage: $0 [configure|manifests|secrets|configmaps|all]"
  echo ""
  echo "  configure   Point kubectl at the EKS cluster"
  echo "  manifests   Apply all Kubernetes manifests in dependency order"
  echo "  secrets     Create K8s secrets from AWS Secrets Manager"
  echo "  configmaps  Patch ConfigMaps with live RDS endpoints"
  echo "  all         Run all steps end-to-end (configure → manifests → secrets → configmaps → manifests)"
  echo ""
}

case "${1:-}" in
  configure)
    bash "$SCRIPT_DIR/configure.sh"
    ;;
  manifests)
    bash "$SCRIPT_DIR/manifests.sh"
    ;;
  secrets)
    bash "$SCRIPT_DIR/secrets.sh"
    ;;
  configmaps)
    bash "$SCRIPT_DIR/configmaps.sh"
    ;;
  all)
    log_info "k8s all — running full Kubernetes deployment"
    echo ""
    log_info "Step 1/5 — Configure kubectl"
    bash "$SCRIPT_DIR/configure.sh"

    log_info "Step 2/5 — Apply manifests (first pass)"
    bash "$SCRIPT_DIR/manifests.sh"

    log_info "Step 3/5 — Create secrets from Secrets Manager"
    bash "$SCRIPT_DIR/secrets.sh"

    log_info "Step 4/5 — Patch ConfigMaps with RDS endpoints"
    bash "$SCRIPT_DIR/configmaps.sh"

    log_info "Step 5/5 — Re-apply manifests (picks up updated config)"
    bash "$SCRIPT_DIR/manifests.sh"

    echo ""
    log_success "Kubernetes deployment complete."
    ;;
  *)
    log_error "Unknown command: '${1:-}'"
    usage
    exit 1
    ;;
esac
