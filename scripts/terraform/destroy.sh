#!/usr/bin/env bash
# terraform/destroy.sh — destroy all Terraform-managed infrastructure
# Called by main.sh. Do not run directly.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

log_warn "This will DESTROY all infrastructure managed by Terraform."
log_warn "This action cannot be undone."
echo ""
read -rp "Type 'yes' to confirm: " CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
  log_info "Destroy cancelled."
  exit 0
fi

log_info "Initialising Terraform..."
terraform -chdir="$TERRAFORM_DIR" init -reconfigure

log_info "Destroying infrastructure..."
terraform -chdir="$TERRAFORM_DIR" destroy -auto-approve

if [[ -f "$TF_OUTPUTS_FILE" ]]; then
  rm "$TF_OUTPUTS_FILE"
  log_info "Removed $TF_OUTPUTS_FILE"
fi

log_success "Infrastructure destroyed."
