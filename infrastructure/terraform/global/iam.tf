# Strict password policy (HIPAA Compliance)
resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length = 14
  require_lowercase_characters = true
  require_uppercase_characters = true
  require_numbers = true
  require_symbols = true
  allow_users_to_change_password = true
  password_reuse_prevention = 24
  max_password_age = 90
}

# OIDC Provider for GitHub Actions (excluding the use of static IAM Keys)
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d34hgh6868jdfs23397b34396831e3780aea1"]
}

# GitHub Actions limited role
resource "aws_iam_role" "github_actions" {
  name = "GitHubActionsWorkflowRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub": "repo:Platform/infrastructure:*"
          }
        }
      }
    ]
  })

  tags = var.common_tags
}

# Specialized deployment policy (Principle of Least Privilege)
resource "aws_iam_policy" "infrastructure_deployment" {
  name = "PlatformInfrastructureDeploymentPolicy"
  description = "Permissions for deploying core Platform infrastructure services"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowScopedInfraManagement"
        Effect = "Allow"
        Action = ["ec2:*", "eks:*", "rds:*", "s3:*", "kms:*", "iam:*", "route53:*", "acm:*", "wafv2:*"]
        Resource = "*"
        Condition = {
          StringEquals = { "aws:ResourceTag/Project": "Platform" }
        }
      },
      {
        Sid    = "DenyBillingAndOrgs"
        Effect = "Deny"
        Action = ["aws-portal:*", "billing:*", "organizations:*"]
        Resource = "*"
      }
    ]
  })
  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "github_actions_attach" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.infrastructure_deployment.arn
}

# Mandatory MFA Policy
resource "aws_iam_policy" "enforce_mfa" {
  name        = "EnforceMFAPolicy"
  description = "Blocks non-MFA access to all activities except managing your own MFA credentials."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowManageOwnMFA"
        Effect = "Allow"
        Action = [
          "iam:CreateVirtualMFADevice",
          "iam:DeleteVirtualMFADevice",
          "iam:EnableMFADevice",
          "iam:ResyncMFADevice",
          "iam:ListMFADevices",
          "iam:ListVirtualMFADevices",
          "iam:ListUsers"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:mfa/$${aws:username}",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/$${aws:username}"
        ]
      },
      {
        Sid    = "DenyAllExceptIfMFA"
        Effect = "Deny"
        NotAction = [
          "iam:CreateVirtualMFADevice",
          "iam:EnableMFADevice",
          "iam:ListMFADevices",
          "iam:ListVirtualMFADevices",
          "iam:ResyncMFADevice",
          "iam:GetAccountPasswordPolicy",
          "iam:ListUsers"
        ]
        Resource = "*"
        Condition = {
          "BoolIfExists" = { "aws:MultiFactorAuthPresent" : "false" }
        }
      }
    ]
  })
}

# The Role of Security Auditor
resource "aws_iam_role" "security_auditor" {
  name = "SecurityAuditorRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
    }]
  })
  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "auditor_read_only" {
  role       = aws_iam_role.security_auditor.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

data "aws_caller_identity" "current" {}