variable "env" {
  description = "The deployment environment name (prod, dev, etc.)"
  type = string
}

variable "notification_email" {
  description = "Email for sending security notifications"
  type = string
}

variable "common_tags" {
  description = "Common tags"
  type = map(string)
  default = {}
}

variable "kms_key_arn" {
  description = "KMS Key ARN for logs encryption"
  type        = string
}

variable "alb_arn_suffix" {
  description = ""
  type = string
}

variable "eks_cluster_name" {
  description = ""
  type = string
}