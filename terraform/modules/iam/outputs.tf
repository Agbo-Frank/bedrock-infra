output "dev_user_name" {
  description = "IAM username for the developer view user"
  value       = aws_iam_user.dev_view.name
}

output "dev_user_arn" {
  description = "ARN of the bedrock-dev-view IAM user"
  value       = aws_iam_user.dev_view.arn
}

output "dev_access_key_id" {
  description = "Access Key ID for bedrock-dev-view (share with grader)"
  value       = aws_iam_access_key.dev_view.id
}

output "dev_secret_access_key" {
  description = "Secret Access Key for bedrock-dev-view (share with grader)"
  value       = aws_iam_access_key.dev_view.secret
  sensitive   = true
}

output "dev_console_password" {
  description = "Initial console password for bedrock-dev-view (share with grader)"
  value       = aws_iam_user_login_profile.dev_view.password
  sensitive   = true
}
