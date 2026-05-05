variable "aws_region" {
  description = "AWS region where resources are deployed"
  type        = string
}

variable "log_group_name" {
  description = "The name of the CloudWatch Log Group for EKS container logs"
  type        = string
}

variable "fluent_bit_role_arn" {
  description = "IAM Role ARN for Fluent Bit with permissions to write to CloudWatch"
  type        = string
}