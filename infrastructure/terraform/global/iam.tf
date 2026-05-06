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

data "aws_caller_identity" "current" {}

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

# ---------------------------------------------------------------------------------------------------------------------
# AWS IAM Identity Center (SSO) - Modern alternative to IAM Users
# ---------------------------------------------------------------------------------------------------------------------

data "aws_ssoadmin_instances" "current" {}

locals {
  sso_instance_arn      = tolist(data.aws_ssoadmin_instances.current.arns)[0]
  sso_instance_id       = tolist(data.aws_ssoadmin_instances.current.identity_store_ids)[0]
  
  # Mapping of permission sets to their managed policies
  permission_sets = {
    Administrator = ["arn:aws:policy/AdministratorAccess"]
    PowerUser     = ["arn:aws:policy/PowerUserAccess"]
    ReadOnly      = ["arn:aws:policy/ReadOnlyAccess"]
    DBAdmin       = ["arn:aws:policy/AmazonRDSFullAccess"]
    Billing       = ["arn:aws:policy/JobFunction/Billing"]
    SecurityAdmin = [
      "arn:aws:policy/IAMFullAccess",
      "arn:aws:policy/AmazonGuardDutyFullAccess",
      "arn:aws:policy/AWSKeyManagementServicePowerUser",
      "arn:aws:policy/AWSWAFConsoleFullAccess"
    ]
    Support       = ["arn:aws:policy/AWSSupportAccess"]
    # Note: PowerUserAccess is used for broad access, but in a real-world scenario 
    # it should be scoped down using ResourceTag/Project conditions.
    Developer     = ["arn:aws:policy/PowerUserAccess"]
    Architect     = ["arn:aws:policy/PowerUserAccess"]
  }
}

resource "aws_ssoadmin_permission_set" "sets" {
  for_each         = local.permission_sets
  name             = each.key
  description      = "Permission set for ${each.key} role"
  instance_arn     = local.sso_instance_arn
  relay_state      = "https://console.aws.amazon.com/"
  session_duration = "PT8H"
  tags             = var.common_tags
}

resource "aws_ssoadmin_managed_policy_attachment" "attachments" {
  for_each = {
    for pair in flatten([
      for set_name, policies in local.permission_sets : [
        for policy in policies : {
          set_name = set_name
          policy   = policy
        }
      ]
    ]) : "${pair.set_name}-${pair.policy}" => pair
  }

  instance_arn       = local.sso_instance_arn
  managed_policy_arn = each.value.policy
  permission_set_arn = aws_ssoadmin_permission_set.sets[each.value.set_name].arn
}

# Apply standard boundary to all SSO Permission Sets for consistency
resource "aws_ssoadmin_permissions_boundary_attachment" "standard" {
  for_each           = aws_ssoadmin_permission_set.sets
  instance_arn       = local.sso_instance_arn
  permission_set_arn = each.value.arn
  
  permissions_boundary {
    customer_managed_policy_reference {
      name = aws_iam_policy.standard_boundary.name
      path = "/"
    }
  }
}

# Attach custom EKS access policy to the Developer permission set
resource "aws_ssoadmin_customer_managed_policy_attachment" "developer_eks" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.sets["Developer"].arn
  customer_managed_policy_reference {
    name = aws_iam_policy.dev_eks_access.name
    path = "/"
  }
}