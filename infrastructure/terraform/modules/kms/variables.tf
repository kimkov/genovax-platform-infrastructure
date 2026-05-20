variable "env" {
  description = "The deployment environment name (prod, dev, etc.)"
  type = string
}

variable "common_tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "s3_replication_role_arn" {
  description = "The ARN of the IAM role used for S3 cross-region replication"
  type        = string
  default     = null
}

variable "eks_node_role_arn" {
  description = "The ARN of the IAM role for EKS worker nodes"
  type        = string
  default     = null
}

variable "ecr_allowed_read_principals" {
  description = "List of ARNs of roles or wildcards that are allowed to decrypt ECR images"
  type        = list(string)
  default     = []
}