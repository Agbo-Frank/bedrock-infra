# ── GitHub OIDC Provider ──────────────────────────────────────────────────────
# Registers GitHub Actions as a trusted identity provider in AWS.
# This allows GitHub Actions workflows to assume IAM roles without storing
# long-lived AWS credentials as GitHub secrets.

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = {
    Name = "${var.title}-github-oidc"
  }
}

# ── GitHub Actions IAM Role ───────────────────────────────────────────────────
# The role GitHub Actions assumes when running terraform plan/apply.
# Trust policy restricts access to only your specific repo.

resource "aws_iam_role" "github_actions" {
  name = "${var.title}-github-actions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_username}/${var.github_repo}:*"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.title}-github-actions"
  }
}

# ── Permissions ───────────────────────────────────────────────────────────────
# AdministratorAccess allows the pipeline to create/modify all AWS resources.
# Scope this down after the project if moving to production.

resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
