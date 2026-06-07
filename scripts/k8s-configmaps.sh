#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

check_deps
load_tf_outputs

NAMESPACE="retail-app"

# ─── Helper: get RDS endpoint by DB identifier ──────────────────────────────

get_rds_endpoint() {
  local db_id="$1"
  aws rds describe-db-instances \
    --region "$REGION" \
    --db-instance-identifier "$db_id" \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text
}

# ─── Catalog ConfigMap (MySQL) ───────────────────────────────────────────────

log_info "Fetching catalog RDS endpoint..."
CATALOG_ENDPOINT=$(get_rds_endpoint "project-bedrock-catalog")

log_info "Patching catalog-config: DB_ENDPOINT=$CATALOG_ENDPOINT"
kubectl patch configmap catalog-config \
  --namespace "$NAMESPACE" \
  --type merge \
  -p "{\"data\":{\"DB_ENDPOINT\":\"$CATALOG_ENDPOINT\"}}"

log_success "catalog-config patched"

# ─── Orders ConfigMap (PostgreSQL) ───────────────────────────────────────────

log_info "Fetching orders RDS endpoint..."
ORDERS_ENDPOINT=$(get_rds_endpoint "project-bedrock-orders")

log_info "Patching orders-config: DB_ENDPOINT=$ORDERS_ENDPOINT"
kubectl patch configmap orders-config \
  --namespace "$NAMESPACE" \
  --type merge \
  -p "{\"data\":{\"DB_ENDPOINT\":\"$ORDERS_ENDPOINT\"}}"

log_success "orders-config patched"

log_success "ConfigMaps updated with live RDS endpoints."
log_info "Run ./scripts/k8s-manifests.sh again to restart pods with new config."
