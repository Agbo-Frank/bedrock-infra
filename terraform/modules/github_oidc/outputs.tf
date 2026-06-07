output "github_actions_role_arn" {
  description = "ARN of the IAM role for GitHub Actions — add this as AWS_ROLE_ARN secret in your repo"
  value       = aws_iam_role.github_actions.arn
}
