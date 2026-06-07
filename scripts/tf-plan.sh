#!/usr/bin/env bash
# tf-plan.sh — run terraform init + plan
# Usage:
#   ./scripts/tf-plan.sh             # standard plan
#   ./scripts/tf-plan.sh -destroy    # plan for destroy

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

check_deps

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
log_info  "To apply this exact plan run: ./scripts/tf-apply.sh"
