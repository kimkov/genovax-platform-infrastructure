variable "project_name" {
  description = "Project name"
  type = string
  default = "GenovaX"
}

variable "owner" {
  description = "Resource Owner (Team/Department)"
  type = string
  default = "Cloud-Architecture-Team"
}

variable "domain_name" {
  description = "Application root domain"
  type = string
  default = "example.com"
}

variable "github_repository" {
  description = "GitHub repository for OIDC federation (format: organization/repo)"
  type        = string
  default     = "GenovaX/infrastructure"
}

variable "oidc_thumbprint_list" {
  description = "List of thumbprints for the OIDC provider (GitHub)"
  type        = list(string)
  default     = [
    "6938fd4d3472f6a175a407de5f70230bb209ee2e", # Primary
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"  # Secondary (DigiCert)
  ]
}

variable "billing_notification_email" {
  description = "Email for budget overage notifications"
  type = string
  default = "admin@example.com"
}

variable "security_notification_email" {
  description = "Email for security notifications (Audit/GuardDuty)"
  type        = string
  default     = "security-officer@example.com"
}

variable "common_tags" {
  description = "Common tags for all resources"
  type = map(string)
  default = {
    Project = "GenovaX"
    ManagedBy = "Terraform"
    Type = "Global"
    Owner = "Cloud-Architecture-Team"
  }
}



variable "allowed_pass_role_patterns" {
  description = "List of role patterns that CI/CD is allowed to pass to services"
  type        = list(string)
  default     = [
    "arn:aws:iam::*:role/eks-node-role-*",
    "arn:aws:iam::*:role/lambda-execution-role-*",
    "arn:aws:iam::*:role/app-execution-role-*"
  ]
}

