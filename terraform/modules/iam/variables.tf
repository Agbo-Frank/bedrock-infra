variable "assets_bucket_name" {
  description = "Name of the S3 assets bucket the dev user can upload to"
  type        = string
  default     = "bedrock-assets-alt-soe-025-4161"
}

variable "title" {
  description = "Name prefix applied to all resource tags"
  type        = string
  default     = "project-bedrock"
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider for IRSA trust policies"
  type        = string
  default     = ""
}

variable "oidc_provider_url" {
  description = "URL of the EKS OIDC provider for IRSA trust policies"
  type        = string
  default     = ""
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB cart table"
  type        = string
  default     = ""
}
