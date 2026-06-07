variable "github_username" {
  description = "GitHub username or organisation that owns the repo"
  type        = string
  default     = "GITHUB_USERNAME"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "project-bedrock"
}

variable "title" {
  description = "Name prefix applied to all resource tags"
  type        = string
  default     = "project-bedrock"
}
