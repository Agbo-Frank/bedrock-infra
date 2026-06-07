#!/usr/bin/env bash
# terraform/main.sh — entry point for all Terraform operations
#
# Usage:
#   ./scripts/terraform/main.sh plan              # preview changes
#   ./scripts/terraform/main.sh plan -destroy     # preview destroy
#   ./scripts/terraform/main.sh apply             # provision infrastructure
#   ./scripts/terraform/main.sh destroy           # tear down infrastructure

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

check_terraform_deps

usage() {
  echo ""
  echo "Usage: $0 [plan|apply|destroy]"
  echo ""
  echo "  plan [-destroy]  Preview what Terraform will create or destroy"
  echo "  apply            Provision all AWS infrastructure"
  echo "  destroy          Tear down all AWS infrastructure"
  echo ""
}

case "${1:-}" in
  plan)
    bash "$SCRIPT_DIR/plan.sh" "${2:-}"
    ;;
  apply)
    bash "$SCRIPT_DIR/apply.sh"
    ;;
  destroy)
    bash "$SCRIPT_DIR/destroy.sh"
    ;;
  *)
    log_error "Unknown command: '${1:-}'"
    usage
    exit 1
    ;;
esac
