# --- GitHub Actions OIDC Role (GitOps branch) ---

data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

locals {
  github_repo   = "luchenzo7/EKS_Deployment"
  github_branch = "gitops"
}

resource "aws_iam_role" "github_actions_oidc" {
  name = "tc2-github-actions-oidc-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${local.github_repo}:ref:refs/heads/${local.github_branch}"
          }
        }
      }
    ]
  })
}

# ECR permissions (simple/dev). Tighten later if you want.
resource "aws_iam_role_policy_attachment" "github_actions_ecr" {
  role       = aws_iam_role.github_actions_oidc.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions_oidc.arn
}
