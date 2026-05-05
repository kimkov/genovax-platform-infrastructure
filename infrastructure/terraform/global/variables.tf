variable "project_name" {
  description = "Project name"
  type = string
  default = "Platform"
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
    Project = "Platform"
    ManagedBy = "Terraform"
    Type = "Global"
    Owner = "Cloud-Architecture-Team"
  }
}