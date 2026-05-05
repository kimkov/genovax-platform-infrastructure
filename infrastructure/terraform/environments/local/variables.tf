variable "aws_region" {
  description = "AWS Region for local development"
  type = string
  default = "us-east-1"
}

variable "env" {
  description = "Environment name"
  type = string
  default = "local"
}

variable "common_tags" {
  description = "Common tags for all local resources"
  type = map(string)
  default = {
    Project     = "Platform"
    Environment = "local"
    ManagedBy   = "Terraform"
    Compliance  = "Local-Dev"
  }
}