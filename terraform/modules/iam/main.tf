resource "aws_iam_user" "dev_view" {
  name = "bedrock-dev-view"

  tags = {
    Name = "bedrock-dev-view"
  }
}

# password_reset_required = true forces the user to set a new password on first login

resource "aws_iam_user_login_profile" "dev_view" {
  user                    = aws_iam_user.dev_view.name
  password_reset_required = false
}

resource "aws_iam_access_key" "dev_view" {
  user = aws_iam_user.dev_view.name
}

resource "aws_iam_user_policy_attachment" "readonly" {
  user       = aws_iam_user.dev_view.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_policy" "dev_s3_put" {
  name        = "${var.title}-dev-s3-put"
  description = "Allows bedrock-dev-view to upload objects to the assets bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:PutObject"
        Resource = "arn:aws:s3:::${var.assets_bucket_name}/*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "dev_s3_put" {
  user       = aws_iam_user.dev_view.name
  policy_arn = aws_iam_policy.dev_s3_put.arn
}

resource "aws_iam_role" "cart_irsa" {
  name = "${var.title}-cart-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:retail-app:cart-sa"
            "${replace(var.oidc_provider_url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.title}-cart-irsa"
  }
}

resource "aws_iam_policy" "cart_dynamodb" {
  name        = "${var.title}-cart-dynamodb"
  description = "Allows cart pod to read and write the DynamoDB cart table"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          var.dynamodb_table_arn,
          "${var.dynamodb_table_arn}/index/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cart_dynamodb" {
  role       = aws_iam_role.cart_irsa.name
  policy_arn = aws_iam_policy.cart_dynamodb.arn
}
