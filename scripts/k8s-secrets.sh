#!/usr/bin/env bash
# k8s-secrets.sh — create Kubernetes secrets from AWS Secrets Manager values
# Must be run AFTER k8s-manifests.sh (namespace must exist)
# Usage: ./scripts/k8s-secrets.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

check_deps
load_tf_outputs

NAMESPACE="retail-app"

# ─── Helper: fetch a secret value from Secrets Manager ──────────────────────

get_secret() {
  local secret_name="$1"
  aws secretsmanager get-secret-value \
    --region "$REGION" \
    --secret-id "$secret_name" \
    --query SecretString \
    --output text | jq -r '.password'
}

# ─── Catalog DB secret (MySQL) ───────────────────────────────────────────────

log_info "Fetching catalog DB password from Secrets Manager..."
CATALOG_PASSWORD=$(get_secret "project-bedrock-catalog-db-password")

kubectl create secret generic catalog-db-secret \
  --namespace "$NAMESPACE" \
  --from-literal=DB_PASSWORD="$CATALOG_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -

log_success "catalog-db-secret applied"

# ─── Orders DB secret (PostgreSQL) ───────────────────────────────────────────

log_info "Fetching orders DB password from Secrets Manager..."
ORDERS_PASSWORD=$(get_secret "project-bedrock-orders-db-password")

kubectl create secret generic orders-db-secret \
  --namespace "$NAMESPACE" \
  --from-literal=DB_PASSWORD="$ORDERS_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -

log_success "orders-db-secret applied"

log_success "All Kubernetes secrets created in namespace: $NAMESPACE"
