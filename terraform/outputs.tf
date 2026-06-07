output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "assets_bucket_name" {
  description = "S3 assets bucket name"
  value       = local.assets_bucket_name
}

output "cart_irsa_role_arn" {
  description = "ARN of the cart IRSA role for the cart-sa ServiceAccount"
  value       = module.iam.cart_irsa_role_arn
}
