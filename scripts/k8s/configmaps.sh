#!/usr/bin/env bash
# k8s/configmaps.sh — patch ConfigMaps with live RDS endpoints
# Must run AFTER manifests.sh (configmaps must exist)
# Called by main.sh. Do not run directly.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

load_tf_outputs

NAMESPACE="retail-app"

# Helper: get RDS endpoint address by DB instance identifier
get_rds_endpoint() {
  local db_id="$1"
  aws rds describe-db-instances \
    --region "$REGION" \
    --db-instance-identifier "$db_id" \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text
}


log_info "Fetching catalog RDS endpoint (project-bedrock-mysql)..."
CATALOG_ENDPOINT=$(get_rds_endpoint "project-bedrock-mysql")

log_info "Patching catalog-config: RETAIL_CATALOG_PERSISTENCE_ENDPOINT=$CATALOG_ENDPOINT:3306"
kubectl patch configmap catalog-config \
  --namespace "$NAMESPACE" \
  --type merge \
  -p "{\"data\":{\"RETAIL_CATALOG_PERSISTENCE_ENDPOINT\":\"$CATALOG_ENDPOINT:3306\"}}"

log_success "catalog-config patched"


log_info "Fetching orders RDS endpoint (project-bedrock-postgres)..."
ORDERS_ENDPOINT=$(get_rds_endpoint "project-bedrock-postgres")

log_info "Patching orders-config: RETAIL_ORDERS_PERSISTENCE_ENDPOINT=$ORDERS_ENDPOINT:5432"
kubectl patch configmap orders-config \
  --namespace "$NAMESPACE" \
  --type merge \
  -p "{\"data\":{\"RETAIL_ORDERS_PERSISTENCE_ENDPOINT\":\"$ORDERS_ENDPOINT:5432\"}}"

log_success "orders-config patched"

log_success "ConfigMaps updated with live RDS endpoints."
