#!/usr/bin/env bash
# deploy.sh — full end-to-end deployment orchestrator
#
# Runs: terraform apply → kubeconfig → manifests → secrets → configmaps → re-apply manifests
#
# Usage:
#   ./scripts/deploy.sh            # full deploy
#   ./scripts/deploy.sh --k8s-only # skip terraform, go straight to k8s steps

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

K8S_ONLY=false
if [[ "${1:-}" == "--k8s-only" ]]; then
  K8S_ONLY=true
  log_warn "--k8s-only: skipping Terraform, using saved outputs from .tf-outputs"
fi

check_deps

echo ""
echo "========================================================"
echo "  Project Bedrock — Full Deployment"
echo "========================================================"
echo ""

# ─── Step 1: Terraform ───────────────────────────────────────────────────────

if [[ "$K8S_ONLY" == false ]]; then
  log_info "Step 1/6 — Terraform apply"
  bash "$SCRIPT_DIR/tf-apply.sh"
else
  log_info "Step 1/6 — Terraform (skipped)"
  load_tf_outputs
fi

# ─── Step 2: kubeconfig ──────────────────────────────────────────────────────

log_info "Step 2/6 — Configure kubectl"
bash "$SCRIPT_DIR/k8s-configure.sh"

# ─── Step 3: Initial manifest apply (creates namespace + configmaps) ─────────

log_info "Step 3/6 — Apply manifests (first pass)"
bash "$SCRIPT_DIR/k8s-manifests.sh"

# ─── Step 4: Create secrets from Secrets Manager ─────────────────────────────

log_info "Step 4/6 — Create Kubernetes secrets"
bash "$SCRIPT_DIR/k8s-secrets.sh"

# ─── Step 5: Patch configmaps with real RDS endpoints ────────────────────────

log_info "Step 5/6 — Patch ConfigMaps with RDS endpoints"
bash "$SCRIPT_DIR/k8s-configmaps.sh"

# ─── Step 6: Re-apply manifests so pods pick up updated config ───────────────

log_info "Step 6/6 — Re-apply manifests (picks up updated secrets + configmaps)"
bash "$SCRIPT_DIR/k8s-manifests.sh"

# ─── Done ────────────────────────────────────────────────────────────────────

echo ""
echo "========================================================"
log_success "Deployment complete!"
echo "========================================================"
echo ""
log_info "ALB address (may take 2-3 min to be assigned):"
kubectl get ingress -n retail-app
echo ""
log_info "Watch pod status:  kubectl get pods -n retail-app -w"
log_info "View logs:         kubectl logs -n retail-app deploy/<name>"
