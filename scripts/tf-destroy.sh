#!/usr/bin/env bash
# tf-destroy.sh — tear down all Terraform-managed infrastructure
# Usage: ./scripts/tf-destroy.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

check_deps

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

# Clean up saved outputs
if [[ -f "$TF_OUTPUTS_FILE" ]]; then
  rm "$TF_OUTPUTS_FILE"
  log_info "Removed $TF_OUTPUTS_FILE"
fi

log_success "Infrastructure destroyed."
