variable "region" {
  description = "AWS region to deploy all resources"
  type        = string
  default     = "us-east-1"
}

variable "title" {
  description = "Name prefix applied to all resource tags"
  type        = string
  default     = "project-bedrock"
}

variable "github_username" {
  description = "GitHub username or org that owns the repo — used to scope the OIDC trust policy"
  type        = string
}

variable "admin_arn" {
  description = "ARN of the IAM identity (user or role) used to administer the EKS cluster locally"
  type        = string
}

