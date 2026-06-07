
#!/usr/bin/env bash
# terraform/plan.sh — terraform init + plan
# Called by main.sh. Do not run directly.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

DESTROY_FLAG=""
if [[ "${1:-}" == "-destroy" ]]; then
  DESTROY_FLAG="-destroy"
  log_warn "Running DESTROY plan — no changes will be made yet"
fi

log_info "Initialising Terraform..."
terraform -chdir="$TERRAFORM_DIR" init -reconfigure

log_info "Running terraform plan${DESTROY_FLAG:+ (destroy)}..."
terraform -chdir="$TERRAFORM_DIR" plan $DESTROY_FLAG -out="$TERRAFORM_DIR/terraform.tfplan"

log_success "Plan saved to terraform/terraform.tfplan"
log_info "To apply: ./scripts/terraform/main.sh apply"
