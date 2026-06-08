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

output "github_oidc_role_arn" {
  description = "ARN of the GitHub Actions IAM role — set as AWS_ROLE_ARN secret in your repo"
  value       = module.github_oidc.github_actions_role_arn
}

output "dev_console_password" {
  description = "Initial console password for bedrock-dev-view (share with grader)"
  value       = module.iam.dev_console_password
  sensitive   = true
}

output "dev_access_key_id" {
  description = "Access Key ID for bedrock-dev-view (share with grader)"
  value       = module.iam.dev_access_key_id
}

output "dev_secret_access_key" {
  description = "Secret Access Key for bedrock-dev-view (share with grader)"
  value       = module.iam.dev_secret_access_key
  sensitive   = true
}
