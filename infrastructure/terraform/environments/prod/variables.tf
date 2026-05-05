variable "aws_region" {
  description = "The AWS region where production resources will be deployed"
  type        = string
  default     = "ue-east-1"
}

variable "env" {
  description = "The name of the environment (production)"
  type        = string
  default     = "prod"
}

variable "db_username" {
  description = "The administrator username for the production database"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "The administrator password for the production database"
  type        = string
  sensitive   = true
}

variable "common_tags" {
  description = "A map of common tags to apply to all resources"
  type        = map(string)
  default     = {
    Project     = "GenovaX"
    Environment = "prod"
    ManagedBy   = "Terraform"
  }
}