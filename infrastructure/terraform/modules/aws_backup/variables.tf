variable "env" {
  description = "Name of the deployment environment (prod, dev, etc.)"
  type = string
}

variable "common_tags" {
  type = map(string)
  default = {}
}

variable "kms_key_arn" {
  description = "KMS key for Backup Vault encryption"
  type = string
}

variable "backup_retention_days" {
  description = "T"
  type = number
  default = 2555
}

variable "cold_storage_after_days" {
  type = number
  default = 30
}

variable "notification_email" {
  type = string
}

variable "backup_selection_tags" {
  type = list(object({
    type = string,
    key = string,
    value = string
  }))
  default = [{
    type = "STRINGEQUALS",
    key = "Backup",
    value = "true"
  }] }

# Disaster Recovery
variable "dr_copy_enabled" {
  type = bool
  default = true
}

variable "dr_destination_vault_arn" {
  description = "ARN Vault in another region for copying backups"
  type = string
  default = null
}

# Vault Lock configurations
variable "vault_lock_min_retention_days" {
  type = number
  default = 7
}

variable "vault_lock_max_retention_days" {
  type = number
  default = 2555
}

variable "vault_lock_changeable_for_days" {
  type = number
  default = 3
}

# List of accounts or roles for Break-glass access (for Vault Policy)
variable "admin_role_arns" {
  description = "List of ARNs of roles that are allowed to delete restore points in exceptional cases"
  type = list(string)
  default = []
}

variable "sns_kms_key_arn" {
  description = "Custom KMS key ARN for SNS topic encryption"
  type        = string
}

variable "enable_restore_testing" {
  description = "Enable automatic recovery check"
  type = bool
  default = true
}

variable "restore_testing_schedule" {
  description = "Recovery Check Schedule (cron)"
  type = string
  default = "cron(0 12 ? * 1 *)" # Every Sunday
}

variable "reports_bucket_name" {
  description = "S3 bucket name for reports (if not specified, it will be created automatically)"
  type = string
  default = null
}

variable "log_retention_days" {
  description = "CloudWatch log retention period"
  type = number
  default = 90
}

variable "tested_resource_types" {
  description = "List of resource types to test for recovery"
  type        = list(string)
  default     = ["RDS", "EBS", "S3", "EC2"]
}