variable "env" {
  description = "The deployment environment name (prod, dev, etc.)"
  type = string
}

variable "repository_names" {
  description = "The name of the repository"
  type = list(string)
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for image encryption"
  type = string
}

variable "common_tags" {
  description = "Common tags for resources"
  type = map(string)
}

variable "allowed_read_principals" {
  description = "List of ARNs of roles or users that are allowed to download images (e.g. EKS node role)"
  type        = list(string)
  default     = []
}