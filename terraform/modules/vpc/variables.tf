variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "title" {
  description = "Name prefix applied to all resource tags"
  type        = string
  default     = "project-bedrock"
}

variable "vpc_name" {
  description = "Name tag for the VPC (must match grading requirement)"
  type        = string
  default     = "project-bedrock-vpc"
}

variable "cluster_name" {
  description = "EKS cluster name used for subnet discovery tags"
  type        = string
  default     = "project-bedrock-cluster"
}