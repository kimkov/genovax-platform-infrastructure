variable "env" {
  description = "The deployment environment name"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "oidc_provider" {
  description = "OIDC provider URL"
  type        = string
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption (used by PHI processor and CSI driver)"
  type        = string
}

variable "velero_bucket_name" {
  description = "S3 bucket name for Velero backups"
  type        = string
}

variable "phi_s3_bucket_arn" {
  description = "ARN of the S3 bucket containing PHI data"
  type        = string
}

variable "external_dns_zone_arns" {
  description = "List of Route53 zone ARNs for External DNS to manage"
  type        = list(string)
  default     = ["*"]
}
