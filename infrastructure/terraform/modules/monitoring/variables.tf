variable "env" {
  description = "The deployment environment name (prod, dev, etc.)"
  type = string
}

variable "notification_email" {
  description = "Email for sending security notifications"
  type = string
}

variable "common_tags" {
  description = "A map of tags to add to all resources"
  type = map(string)
  default = {}
}

variable "kms_key_arn" {
  description = "KMS Key ARN for logs encryption"
  type        = string
}

variable "alb_arn_suffix" {
  description = "The ARN suffix of the ALB for use with CloudWatch Metrics"
  type = string
}

variable "eks_cluster_name" {
  description = "The name of the EKS cluster for monitoring and logs"
  type = string
}