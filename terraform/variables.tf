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

variable "environment" {
  description = "Environment label applied to resources"
  type        = string
  default     = "prod"
}
