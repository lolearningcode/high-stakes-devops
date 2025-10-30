# GitHub Actions OIDC Provider and IAM Role
# This allows GitHub Actions to authenticate to AWS securely without storing AWS keys

# OIDC Identity Provider for GitHub Actions (use existing one)
data "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"
}

# IAM Role for GitHub Actions (use existing one)
data "aws_iam_role" "github_actions" {
  name = "github-actions-terraform-role"
}

# IAM Policy for Terraform operations (use existing one)
data "aws_iam_policy" "terraform_policy" {
  name = "github-actions-terraform-policy"
}

# Additional outputs for GitHub Actions
output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions IAM role"
  value       = data.aws_iam_role.github_actions.arn
}

output "github_actions_oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider"
  value       = data.aws_iam_openid_connect_provider.github_actions.arn
}
