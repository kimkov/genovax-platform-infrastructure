resource "aws_iam_group" "architects" {
  name = "CloudArchitects"
}

resource "aws_iam_group" "developers" {
  name = "Developers"
}

resource "aws_iam_group" "testers" {
  name = "QA-Testers"
}

resource "aws_iam_group" "dbas" {
  name = "DatabaseAdmins"
}

# ---- Linking policies to groups ----

# Architects: Full access except billing
resource "aws_iam_group_policy_attachment" "architects_full_access" {
  group      = aws_iam_group.architects.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

resource "aws_iam_group_policy_attachment" "arch_iam" {
  group      = aws_iam_group.architects.name
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}

# Developers: ReadOnly + custom access to EKS and logs
resource "aws_iam_group_policy_attachment" "developers_read_only" {
  group = aws_iam_group.developers.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Testers: Read-Only + CloudWatch
resource "aws_iam_group_policy_attachment" "testers_read_only" {
  group = aws_iam_group.testers.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Database Administrators: RDS + Backup
resource "aws_iam_group_policy_attachment" "dba_rds" {
  group      = aws_iam_group.dbas.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}

resource "aws_iam_group_policy_attachment" "dba_backup" {
  group      = aws_iam_group.dbas.name
  policy_arn = "arn:aws:iam::aws:policy/AWSBackupFullAccess"
}

# ---- Custom policies ----

# Access to EKS for developers
resource "aws_iam_policy" "dev_eks_access" {
  name = "DeveloperEKSAccess"
  description = "Allows developers to interact with EKS clusters and logs"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:AccessKubernetesApi",
          "eks:ListNodegroups"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:GetLogEvents",
          "logs:FilterLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups"
        ]
        Resource = "arn:aws:logs:*:*:log-group:/aws/eks/*"
      }
    ]
  })
}

resource "aws_iam_group_policy_attachment" "dev_eks_attach" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.dev_eks_access.arn
}

# Mandatory MFA for all groups
resource "aws_iam_group_policy_attachment" "arch_mfa" {
  group      = aws_iam_group.architects.name
  policy_arn = aws_iam_policy.enforce_mfa.arn
}

resource "aws_iam_group_policy_attachment" "dev_mfa" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.enforce_mfa.arn
}

resource "aws_iam_group_policy_attachment" "qa_mfa" {
  group      = aws_iam_group.testers.name
  policy_arn = aws_iam_policy.enforce_mfa.arn
}

resource "aws_iam_group_policy_attachment" "dba_mfa" {
  group      = aws_iam_group.dbas.name
  policy_arn = aws_iam_policy.enforce_mfa.arn
}

# Permission Boundary
resource "aws_iam_policy" "standard_boundary" {
  name        = "GenovaXStandardBoundary"
  description = "Limits maximum permissions that can be granted to delegated roles"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowEverythingExceptCritical"
        Effect = "Allow"
        Action = "*"
        Resource = "*"
      },
      {
        Sid = "DenyAccessToAuditLogs"
        Effect = "Deny"
        Action = [
          "s3:DeleteBucket",
          "s3:DeleteObject",
          "cloudtrail:DeleteTrail",
          "cloudtrail:StopLogging"
        ]
        Resource = "*"
      },
      {
        Sid = "DenyBillingAndOrgs"
        Effect = "Deny"
        Action = [
          "aws-portal:*",
          "billing:*",
          "organizations:*"
        ]
        Resource = "*"
      }
    ]
  })
}

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
            "token.actions.githubusercontent.com:sub": "repo:GenovaX/infrastructure:*"
          }
        }
      }
    ]
  })

  tags = var.common_tags
}

# Specialized deployment policy (Principle of Least Privilege)
resource "aws_iam_policy" "infrastructure_deployment" {
  name = "GenovaXInfrastructureDeploymentPolicy"
  description = "Permissions for deploying core GenovaX infrastructure services"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowScopedInfraManagement"
        Effect = "Allow"
        Action = ["ec2:*", "eks:*", "rds:*", "s3:*", "kms:*", "iam:*", "route53:*", "acm:*", "wafv2:*"]
        Resource = "*"
        Condition = {
          StringEquals = { "aws:ResourceTag/Project": "GenovaX" }
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