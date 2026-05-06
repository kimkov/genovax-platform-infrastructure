variable "env" {
  description = "Deployment environment name (prod, dev etc.)"
  type        = string
}

variable "vpc_cidr" {
  description = "The IPv4 CIDR block for the VPC"
  type        = string
  validation {
    condition = can(cidrnetmask(var.vpc_cidr))
    error_message = "The VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "A list of availability zones in the region for subnet distribution"
  type        = list(string)
}

variable "kms_key_arn" {
  description = "ARN KMS key for encrypting resources (S3, Flow Logs) with rotation support."
  type = string
}

variable "log_bucket_id" {
  description = "The ID (name) of the S3 bucket where VPC Flow Logs will be stored"
  type        = string
}

variable "common_tags" {
  description = "General tags for all resources"
  type = map(string)
  default = {
    Project            = "GenovaX"
    DataClassification = "PHI"
    Compliance         = "High-Compliance"
    ManagedBy          = "Terraform"
  }
}

variable "owner" {
  description = "Resource Owner (Team or Department)"
  type = string
  default = "GenovaXTeam"
}

variable "enable_ipv6" {
  description = "Enables IPv6 support for the VPC and subnets"
  type        = bool
  default     = true
}

variable "assign_generated_ipv6_cidr_block" {
  description = "Requests an Amazon-provided IPv6 CIDR block for the VPC"
  type        = bool
  default     = true
}