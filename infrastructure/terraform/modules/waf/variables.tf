variable "env" {
  description = "Deployment environment name (prod, dev etc.)"
  type        = string
}

variable "common_tags" {
  description = "List of common tags for all resources"
  type        = map(string)
  default     = {}
}

variable "kms_key_arn" {
  description = "KMS Key ARN for log encryption (S3)"
  type        = string
}