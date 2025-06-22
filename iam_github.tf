resource "aws_iam_policy" "no_role_change_policy" {
  name        = "no_role_change_policy"
  description = "Policy to prevent role changes"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "sts:AssumeRole"
        Effect   = "Deny"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "github_actions_policy" {
  name        = "github_actions_policy"
  description = "Policy for CI/CD with Github Actions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:*",
          "route53:*",
          "s3:*",
          "iam:*",
          "sqs:*",
          "events:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_openid_connect_provider" "github_actions_provider" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
}

resource "aws_iam_role" "github_actions_role" {
  name = "github_actions_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${var.account_id}:oidc-provider/token.actions.githubusercontent.com"
      }
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.repo_owner}/${var.repo_name}:*"
        }
      }
    }]
  })
}

locals {
  github_actions_policy_arns = {
    no_role_change_policy = aws_iam_policy.no_role_change_policy.arn
    github_actions_policy = aws_iam_policy.github_actions_policy.arn
  }
}

resource "aws_iam_role_policy_attachment" "github_actions_policy_attachment" {
  for_each = local.github_actions_policy_arns

  role       = aws_iam_role.github_actions_role.name
  policy_arn = each.value
}
