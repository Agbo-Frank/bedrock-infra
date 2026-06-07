#!/usr/bin/env bash
# deploy.sh — full end-to-end deployment orchestrator
#
# Usage:
#   ./scripts/deploy.sh             # terraform apply + full k8s deploy
#   ./scripts/deploy.sh --k8s-only  # skip terraform, re-deploy k8s only

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

check_terraform_deps
check_k8s_deps


K8S_ONLY=false
if [[ "${1:-}" == "--k8s-only" ]]; then
  K8S_ONLY=true
  log_warn "--k8s-only: skipping Terraform, using saved outputs"
fi

echo ""
echo "========================================================"
echo "  Project Bedrock — Full Deployment"
echo "========================================================"
echo ""


if [[ "$K8S_ONLY" == false ]]; then
  log_info "Phase 1 — Terraform"
  bash "$SCRIPT_DIR/terraform/main.sh" apply
else
  log_info "Phase 1 — Terraform (skipped)"
  load_tf_outputs
fi


log_info "Phase 2 — Kubernetes"
bash "$SCRIPT_DIR/k8s/main.sh" all


echo ""
echo "========================================================"
log_success "Deployment complete!"
echo "========================================================"
echo ""
log_info "ALB address (may take 2-3 min to be assigned):"
kubectl get ingress -n retail-app
echo ""
log_info "Watch pods:  kubectl get pods -n retail-app -w"
log_info "View logs:   kubectl logs -n retail-app deploy/<name>"
