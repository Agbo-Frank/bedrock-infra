#!/usr/bin/env bash
# k8s/secrets.sh — create Kubernetes secrets from AWS Secrets Manager values
# Must run AFTER manifests.sh (namespace must exist)
# Called by main.sh. Do not run directly.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

load_tf_outputs

NAMESPACE="retail-app"

# Helper: fetch password field from a Secrets Manager secret
get_secret_password() {
  local secret_id="$1"
  aws secretsmanager get-secret-value \
    --region "$REGION" \
    --secret-id "$secret_id" \
    --query SecretString \
    --output text | jq -r '.password'
}


log_info "Fetching catalog DB password from Secrets Manager..."
CATALOG_PASSWORD=$(get_secret_password "project-bedrock/rds/mysql")

kubectl create secret generic catalog-db-secret \
  --namespace "$NAMESPACE" \
  --from-literal=RETAIL_CATALOG_PERSISTENCE_PASSWORD="$CATALOG_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -

log_success "catalog-db-secret applied"


log_info "Fetching orders DB password from Secrets Manager..."
ORDERS_PASSWORD=$(get_secret_password "project-bedrock/rds/postgres")

kubectl create secret generic orders-db-secret \
  --namespace "$NAMESPACE" \
  --from-literal=RETAIL_ORDERS_PERSISTENCE_PASSWORD="$ORDERS_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -

log_success "orders-db-secret applied"

log_success "All Kubernetes secrets created in namespace: $NAMESPACE"
