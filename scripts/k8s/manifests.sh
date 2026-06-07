#!/usr/bin/env bash
# k8s/manifests.sh — apply all Kubernetes manifests in dependency order
# Called by main.sh. Do not run directly.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

log_info "Applying Kubernetes manifests..."

# 1. Namespace — must exist before everything else
log_info "1/10  Namespace"
kubectl apply -f "$K8S_DIR/namespace.yaml"

# 2. RBAC
log_info "2/10  RBAC"
kubectl apply -f "$K8S_DIR/rbac/dev-view-binding.yaml"

# 3. IngressClass — must exist before Ingress
log_info "3/10  IngressClass"
kubectl apply -f "$K8S_DIR/ingressclass.yaml"

# 4. Infrastructure (Redis, RabbitMQ)
log_info "4/10  Redis"
kubectl apply -f "$K8S_DIR/infra/redis.yaml"

log_info "5/10  RabbitMQ"
kubectl apply -f "$K8S_DIR/infra/rabbitmq.yaml"

# 5. Cart — ServiceAccount first (IRSA annotation must be present before pod starts)
log_info "6/10  Cart"
kubectl apply -f "$K8S_DIR/backend/cart/serviceaccount.yaml"
kubectl apply -f "$K8S_DIR/backend/cart/configmap.yaml"
kubectl apply -f "$K8S_DIR/backend/cart/service.yaml"
kubectl apply -f "$K8S_DIR/backend/cart/deployment.yaml"

# 6. Catalog
log_info "7/10  Catalog"
kubectl apply -f "$K8S_DIR/backend/catalog/configmap.yaml"
kubectl apply -f "$K8S_DIR/backend/catalog/secret.yaml"
kubectl apply -f "$K8S_DIR/backend/catalog/service.yaml"
kubectl apply -f "$K8S_DIR/backend/catalog/deployment.yaml"

# 7. Checkout
log_info "8/10  Checkout"
kubectl apply -f "$K8S_DIR/backend/checkout/configmap.yaml"
kubectl apply -f "$K8S_DIR/backend/checkout/service.yaml"
kubectl apply -f "$K8S_DIR/backend/checkout/deployment.yaml"

# 8. Orders
log_info "9/10  Orders"
kubectl apply -f "$K8S_DIR/backend/orders/configmap.yaml"
kubectl apply -f "$K8S_DIR/backend/orders/secret.yaml"
kubectl apply -f "$K8S_DIR/backend/orders/service.yaml"
kubectl apply -f "$K8S_DIR/backend/orders/deployment.yml"

# 9. UI (frontend)
log_info "10/10 UI"
kubectl apply -f "$K8S_DIR/frontend/ui/configmap.yaml"
kubectl apply -f "$K8S_DIR/frontend/ui/service.yaml"
kubectl apply -f "$K8S_DIR/frontend/ui/deployment.yaml"

# 10. Ingress — last, depends on services being ready
log_info "Ingress"
kubectl apply -f "$K8S_DIR/ingress.yaml"

echo ""
log_success "All manifests applied."
kubectl get all -n retail-app
echo ""
log_info "ALB address (appears after ~2 minutes):"
kubectl get ingress -n retail-app
