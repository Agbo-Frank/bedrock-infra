#!/usr/bin/env bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Absolute path to the scripts directory (works regardless of where scripts are called from)
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPTS_DIR/.." && pwd)"
TERRAFORM_DIR="$REPO_DIR/terraform"
K8S_DIR="$REPO_DIR/k8s"
TF_OUTPUTS_FILE="$SCRIPTS_DIR/.tf-outputs"

# ─── Logging ────────────────────────────────────────────────────────────────

log_info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_success() { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# ─── Dependency check ───────────────────────────────────────────────────────

check_deps() {
  local missing=0
  for cmd in terraform aws kubectl jq; do
    if ! command -v "$cmd" &>/dev/null; then
      log_error "Required tool not found: $cmd"
      missing=1
    fi
  done
  if [[ $missing -eq 1 ]]; then
    log_error "Install missing tools and re-run."
    exit 1
  fi
  log_success "All required tools found (terraform, aws, kubectl, jq)"
}

# ─── Terraform output helper ────────────────────────────────────────────────

get_tf_output() {
  local key="$1"
  terraform -chdir="$TERRAFORM_DIR" output -raw "$key" 2>/dev/null
}

# ─── Load saved terraform outputs ───────────────────────────────────────────

load_tf_outputs() {
  if [[ ! -f "$TF_OUTPUTS_FILE" ]]; then
    log_error ".tf-outputs not found. Run tf-apply.sh first."
    exit 1
  fi
  # shellcheck source=/dev/null
  source "$TF_OUTPUTS_FILE"
  log_info "Loaded terraform outputs from $TF_OUTPUTS_FILE"
}
