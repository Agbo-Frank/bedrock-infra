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
