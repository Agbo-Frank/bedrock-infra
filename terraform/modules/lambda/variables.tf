variable "title" {
  description = "Name prefix applied to all resource tags"
  type        = string
  default     = "project-bedrock"
}

variable "assets_bucket_name" {
  description = "Name of the S3 assets bucket"
  type        = string
  default     = "bedrock-assets-alt-soe-025-4161"
}

variable "lambda_source_path" {
  description = "Path to the Lambda function source code directory"
  type        = string
  default     = "../../lambda"
}
