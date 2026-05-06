# ---- IAM Groups ----

resource "aws_iam_group" "architects" {
  name = var.iam_group_names["architects"]
}

resource "aws_iam_group" "developers" {
  name = var.iam_group_names["developers"]
}

resource "aws_iam_group" "testers" {
  name = var.iam_group_names["testers"]
}

resource "aws_iam_group" "dbas" {
  name = var.iam_group_names["dbas"]
}

# ---- Group Policy Attachments ----

# Architects: Controlled by variable for easy JIT migration
resource "aws_iam_group_policy_attachment" "architects_attach" {
  for_each   = toset(var.architect_policy_arns)
  group      = aws_iam_group.architects.name
  policy_arn = each.value
}

# Developers & Testers
resource "aws_iam_group_policy_attachment" "developers_read_only" {
  group      = aws_iam_group.developers.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_group_policy_attachment" "testers_read_only" {
  group      = aws_iam_group.testers.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Database Administrators: RDS + Backup
resource "aws_iam_group_policy_attachment" "dba_rds" {
  group      = aws_iam_group.dbas.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}

# Mandatory MFA for all groups
resource "aws_iam_group_policy_attachment" "mfa_enforcement" {
  for_each = toset([
    aws_iam_group.architects.name,
    aws_iam_group.developers.name,
    aws_iam_group.testers.name,
    aws_iam_group.dbas.name
  ])
  group = each.value
  policy_arn = aws_iam_policy.enforce_mfa.arn
}

# ---- Permissions Boundary (Critical for Production Security) ----
resource "aws_iam_policy" "standard_boundary" {
  name        = "${var.project_name}StandardBoundary"
  description = "Limits maximum permissions that can be granted to delegated roles"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowAllServices"
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      },
      {
        Sid      = "DenyCriticalDeletions"
        Effect   = "Deny"
        Action   = [
          "ec2:DeleteVpc", "ec2:DeleteSubnet", "rds:DeleteDBInstance",
          "eks:DeleteCluster", "s3:DeleteBucket"
        ]
        Resource = "*"
        Condition = {
          StringEquals = { "aws:ResourceTag/Critical": "true" }
        }
      },
      {
        Sid      = "DenyAccessToAuditLogs"
        Effect   = "Deny"
        Action   = ["s3:DeleteBucket", "s3:DeleteObject", "cloudtrail:DeleteTrail", "cloudtrail:StopLogging"]
        # Protect audit logs bucket
        Resource = [
          aws_s3_bucket.audit_logs.arn,
          "${aws_s3_bucket.audit_logs.arn}/*"
        ]
      },
      {
        Sid      = "RestrictIAMManagement"
        Effect   = "Deny"
        Action   = [
          "iam:DeletePermissionsBoundary",
          "iam:DeleteRolePermissionsBoundary",
          "iam:DeleteUserPermissionsBoundary"
        ]
        Resource = "*"
      }
    ]
  })
}

# OIDC Provider for GitHub Actions Role
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = var.oidc_thumbprint_list
}

resource "aws_iam_role" "github_actions" {
  name                 = "GitHubActionsWorkflowRole"
  permissions_boundary = aws_iam_policy.standard_boundary.arn

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Condition = {
        StringLike = {
          "token.actions.githubusercontent.com:sub": "repo:${var.github_repository}:*"
        }
      }
    }]
  })
  tags = var.common_tags
}

# Specialized Deployment Policy (Principle of Least Privilege + Boundary Enforcement)
resource "aws_iam_policy" "infrastructure_deployment" {
  name        = "GenovaXInfrastructureDeploymentPolicy"
  description = "Permissions for CI/CD to manage infrastructure with mandatory boundary enforcement"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowScopedInfraManagement"
        Effect   = "Allow"
        Action   = ["ec2:*", "eks:*", "rds:*", "s3:*", "kms:*", "route53:*", "acm:*", "wafv2:*"]
        Resource = "*"
        Condition = {
          StringEquals = { "aws:ResourceTag/Project": var.project_name }
        }
      },
      {
        Sid      = "EnforceBoundaryOnRoleCreation"
        Effect   = "Allow"
        Action   = ["iam:CreateRole", "iam:AttachRolePolicy", "iam:PutRolePolicy", "iam:TagRole"]
        Resource = "*"
        Condition = {
          StringEquals = { "iam:PermissionsBoundary": aws_iam_policy.standard_boundary.arn }
        }
      },
      {
        Sid      = "AllowIAMReadOnly"
        Effect   = "Allow"
        Action   = ["iam:Get*", "iam:List*"]
        Resource = "*"
      },
      {
        Sid      = "AllowScopedPassRole"
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = var.allowed_pass_role_patterns
      }
    ]
  })
  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "github_actions_attach" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.infrastructure_deployment.arn
}

# Security & MFA Policies
resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_uppercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
  password_reuse_prevention      = 24
  max_password_age               = 90
}

resource "aws_iam_policy" "enforce_mfa" {
  name        = "EnforceMFAPolicy"
  description = "Blocks all access if MFA is not present, except for MFA management."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowManageOwnMFA"
        Effect = "Allow"
        Action = ["iam:*VirtualMFADevice", "iam:EnableMFADevice", "iam:ResyncMFADevice", "iam:List*MFADevices"]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:mfa/$${aws:username}",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/$${aws:username}"
        ]
      },
      {
        Sid    = "DenyAllExceptIfMFA"
        Effect = "Deny"
        NotAction = ["iam:*VirtualMFADevice", "iam:EnableMFADevice", "iam:List*MFADevices", "iam:GetAccountPasswordPolicy"]
        Resource = "*"
        Condition = { "BoolIfExists" = { "aws:MultiFactorAuthPresent" : "false" } }
      }
    ]
  })
}

data "aws_caller_identity" "current" {}

# ---- SAML Provider & Federated Access (Office 365 / Azure AD) ----
resource "aws_iam_saml_provider" "office365" {
  count                  = var.office365_saml_metadata_document != "" ? 1 : 0
  name                   = "Office365"
  saml_metadata_document = var.office365_saml_metadata_document
}

resource "aws_iam_role" "federated_admin" {
  count = var.office365_saml_metadata_document != "" ? 1 : 0
  name  = "FederatedAdminRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithSAML"
      Effect = "Allow"
      Principal = { Federated = aws_iam_saml_provider.office365[0].arn }
      Condition = {
        StringEquals = {
          "SAML:aud" = "https://signin.aws.amazon.com/saml"
        }
      }
    }]
  })
  
  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "federated_admin_attach" {
  count      = var.office365_saml_metadata_document != "" ? 1 : 0
  role       = aws_iam_role.federated_admin[0].name
  policy_arn = "arn:aws:policy/AdministratorAccess"
}

# Access to EKS for developers
resource "aws_iam_policy" "dev_eks_access" {
  name        = "DeveloperEKSAccess"
  description = "Allows developers to interact with EKS clusters and logs"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEKSRead"
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
        Sid    = "AllowEKSLogsRead"
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

# Security Auditor Role: a role for conducting security audits
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