variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "project-bedrock-cluster"
}

variable "subnet_ids" {
  description = "List of subnet IDs to deploy the EKS cluster into"
  type        = list(string)
  default     = []
}

variable "dev_user_arn" {
  description = "ARN of the bedrock-dev-view IAM user for EKS access entry"
  type        = string
  default     = ""
}
