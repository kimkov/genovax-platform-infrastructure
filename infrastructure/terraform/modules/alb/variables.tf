variable "cluster_name" {}
variable "vpc_id" {}
variable "aws_region" {}
variable "role_arn" {
  description = "IAM Role ARN for AWS Load Balancer Controller"
  type        = string
}