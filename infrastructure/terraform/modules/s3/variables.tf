variable "env" {
  description = "The deployment environment name"
  type        = string
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key for S3 encryption in primary region"
  type        = string
}

variable "kms_key_arn_secondary" {
  description = "The ARN of the KMS key for S3 encryption in secondary region"
  type = string
}

variable "log_bucket_id" {
  description = "The ID of the S3 bucket for access logs"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type = map(string)
  default = {}
}

variable "lifecycle_intelligent_tiering_days" {
  description = "Days after which objects transition to Intelligent Tiering"
  type = number
  default = 30
}

variable "lifecycle_glacier_days" {
  description = "Days after which objects transition to Glacier"
  type = number
  default = 365
}
