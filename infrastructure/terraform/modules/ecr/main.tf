terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.17.0"
    }
  }
}

resource "aws_ecr_repository" "this" {
  for_each = toset(var.repository_names)

  name                 = each.key
  image_tag_mutability = "IMMUTABLE"

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.kms_key_arn
  }

  tags = merge(var.common_tags, {
    Name = each.key
  })
}

# Lifecycle policy for cost control and safety
resource "aws_ecr_lifecycle_policy" "this" {
  for_each   = aws_ecr_repository.this
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Delete untagged images older than 7 days"
        selection = {
          tagStatus     = "untagged"
          countType     = "sinceImagePushed"
          countUnit     = "days"
          countNumber   = 7
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep only the last 50 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 50
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Access Policy (Least Privilege)
resource "aws_ecr_repository_policy" "this" {
  for_each   = aws_ecr_repository.this
  repository = each.value.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPullAccess"
        Effect = "Allow"
        Principal = {
          AWS = var.allowed_read_principals
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      }
    ]
  })
}

resource "aws_ecr_registry_scanning_configuration" "this" {
  scan_type = "ENHANCED"

  rule {
    scan_frequency = "CONTINUOUS_SCAN"
    repository_filter {
      filter      = "*"
      filter_type = "WILDCARD"
    }
  }
}