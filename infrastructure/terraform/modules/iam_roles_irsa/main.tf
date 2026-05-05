terraform {
  required_providers {
    http = {
      source  = "hashicorp/http"
      version = ">= 3.0.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.name
}

# --- AWS Load Balancer Controller ---
data "http" "lbc_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"
}

resource "aws_iam_policy" "lbc" {
  name        = "${var.cluster_name}-lbc-policy"
  description = "IAM policy for AWS Load Balancer Controller"
  policy      = data.http.lbc_iam_policy.response_body
  tags        = var.common_tags
}

resource "aws_iam_role" "lbc" {
  name = "${var.cluster_name}-lbc-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Condition = {
        StringEquals = {
          "${var.oidc_provider}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          "${var.oidc_provider}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "lbc" {
  policy_arn = aws_iam_policy.lbc.arn
  role       = aws_iam_role.lbc.name
}

# --- Secrets Store CSI Driver ---
resource "aws_iam_role" "secrets_store_csi" {
  name = "${var.cluster_name}-secrets-store-csi-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Condition = {
        StringEquals = {
          "${var.oidc_provider}:sub" = "system:serviceaccount:kube-system:csi-secrets-store-provider-aws"
        }
      }
    }]
  })
  tags = var.common_tags
}

resource "aws_iam_policy" "secrets_store_csi" {
  name        = "${var.cluster_name}-secrets-store-csi-policy"
  description = "Policy for Secrets Store CSI Driver to access Secrets Manager and KMS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
        Effect   = "Allow"
        Resource = ["arn:${local.partition}:secretsmanager:${local.region}:${local.account_id}:secret:${var.env}/*"]
      },
      {
        Action   = ["kms:Decrypt"]
        Effect   = "Allow"
        Resource = [var.kms_key_arn]
      }
    ]
  })
  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "secrets_store_csi" {
  policy_arn = aws_iam_policy.secrets_store_csi.arn
  role       = aws_iam_role.secrets_store_csi.name
}

# --- Velero Backup ---
resource "aws_iam_role" "velero" {
  name = "${var.cluster_name}-velero-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Condition = {
        StringEquals = {
          "${var.oidc_provider}:sub" = "system:serviceaccount:velero:velero"
        }
      }
    }]
  })
  tags = var.common_tags
}

resource "aws_iam_policy" "velero" {
  name        = "${var.cluster_name}-velero-policy"
  description = "Policy for Velero backups to S3 and EC2 snapshots"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots",
          "ec2:CreateSnapshot",
          "ec2:CreateTagName",
          "ec2:CreateVolume",
          "ec2:DeleteSnapshot"
        ]
        Effect   = "Allow"
        Resource = ["*"]
      },
      {
        Action = [
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObject",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts"
        ]
        Effect   = "Allow"
        Resource = ["arn:${local.partition}:s3:::${var.velero_bucket_name}/*"]
      },
      {
        Action   = ["s3:ListBucket"]
        Effect   = "Allow"
        Resource = ["arn:${local.partition}:s3:::${var.velero_bucket_name}"]
      }
    ]
  })
  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "velero" {
  policy_arn = aws_iam_policy.velero.arn
  role       = aws_iam_role.velero.name
}

# --- Cluster Autoscaler ---
resource "aws_iam_role" "cluster_autoscaler" {
  name = "${var.cluster_name}-cluster-autoscaler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Condition = {
        StringEquals = {
          "${var.oidc_provider}:sub" = "system:serviceaccount:kube-system:cluster-autoscaler"
        }
      }
    }]
  })
  tags = var.common_tags
}

resource "aws_iam_policy" "cluster_autoscaler" {
  name        = "${var.cluster_name}-cluster-autoscaler-policy"
  description = "Policy for Cluster Autoscaler to manage ASGs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "ec2:DescribeLaunchTemplateVersions"
        ]
        Effect   = "Allow"
        Resource = ["*"]
      },
      {
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "autoscaling:UpdateAutoScalingGroup"
        ]
        Effect   = "Allow"
        Resource = ["*"]
        Condition = {
          StringEquals = {
            "autoscaling:ResourceTag/kubernetes.io/cluster/${var.cluster_name}" = "owned"
          }
        }
      }
    ]
  })
  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
  role       = aws_iam_role.cluster_autoscaler.name
}

# --- External DNS ---
resource "aws_iam_role" "external_dns" {
  name = "${var.cluster_name}-external-dns-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Condition = {
        StringEquals = {
          "${var.oidc_provider}:sub" = "system:serviceaccount:kube-system:external-dns"
        }
      }
    }]
  })
  tags = var.common_tags
}

resource "aws_iam_policy" "external_dns" {
  name        = "${var.cluster_name}-external-dns-policy"
  description = "Policy for External DNS to manage Route53 records"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["route53:ChangeResourceRecordSets"]
        Effect   = "Allow"
        Resource = var.external_dns_zone_arns
      },
      {
        Action = [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets"
        ]
        Effect   = "Allow"
        Resource = ["*"]
      }
    ]
  })
  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "external_dns" {
  policy_arn = aws_iam_policy.external_dns.arn
  role       = aws_iam_role.external_dns.name
}

# --- Cert-Manager ---
resource "aws_iam_role" "cert_manager" {
  name = "${var.cluster_name}-cert-manager-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Condition = {
        StringEquals = {
          "${var.oidc_provider}:sub" = "system:serviceaccount:cert-manager:cert-manager"
        }
      }
    }]
  })
  tags = var.common_tags
}

resource "aws_iam_policy" "cert_manager" {
  name        = "${var.cluster_name}-cert-manager-policy"
  description = "Policy for Cert-Manager to solve DNS-01 challenges"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["route53:GetChange"]
        Effect   = "Allow"
        Resource = ["arn:${local.partition}:route53:::change/*"]
      },
      {
        Action   = ["route53:ChangeResourceRecordSets", "route53:ListResourceRecordSets"]
        Effect   = "Allow"
        Resource = var.external_dns_zone_arns
      },
      {
        Action   = ["route53:ListHostedZonesByName"]
        Effect   = "Allow"
        Resource = ["*"]
      }
    ]
  })
  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "cert_manager" {
  policy_arn = aws_iam_policy.cert_manager.arn
  role       = aws_iam_role.cert_manager.name
}

# --- PHI Processor (Application Role) ---
resource "aws_iam_role" "phi_processor" {
  name = "${var.cluster_name}-phi-processor-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Condition = {
        StringEquals = {
          "${var.oidc_provider}:sub" = "system:serviceaccount:phi-apps:phi-processor"
        }
      }
    }]
  })
  tags = var.common_tags
}

resource "aws_iam_policy" "phi_processor" {
  name        = "${var.cluster_name}-phi-processor-policy"
  description = "Policy for PHI Processor to access medical data in S3 and KMS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = [
          var.phi_s3_bucket_arn,
          "${var.phi_s3_bucket_arn}/*"
        ]
      },
      {
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Effect   = "Allow"
        Resource = [var.kms_key_arn]
      }
    ]
  })
  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "phi_processor" {
  policy_arn = aws_iam_policy.phi_processor.arn
  role       = aws_iam_role.phi_processor.name
}

# Fluent Bit (Logging)
resource "aws_iam_role" "fluent_bit" {
  name = "${var.cluster_name}-fluent-bit-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Condition = {
        StringEquals = {
          "${var.oidc_provider}:sub" = "system:serviceaccount:logging:aws-for-fluent-bit"
        }
      }
    }]
  })
  tags = var.common_tags
}

resource "aws_iam_policy" "fluent_bit" {
  name = "${var.cluster_name}-fluent-bit-policy"
  description = "Policy for Fluent Bit to send logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = ["arn:aws:logs:*:*:*"]
      }
    ]
  })
  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "fluent_bit" {
  policy_arn = aws_iam_policy.fluent_bit.arn
  role       = aws_iam_role.fluent_bit.name
}