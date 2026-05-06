variable "aws_region" {
  description = "AWS Region for deploying development resources"
  type = string
  default = "us-east-1"
}

variable "env" {
  description = "Environment name"
  type = string
  default = "dev"
}

variable "db_username" {
  description = "Database administrator name"
  type = string
  sensitive = true
  default = "devadmin"
}

variable "common_tags" {
  description = "General tags for all resources"
  type = map(string)
  default = {
    Project     = "GenovaX"
    Environment = "dev"
    ManagedBy   = "Terraform"
    Compliance  = "High-Compliance"
  }
}