# General Configuration
variable "env" {
  description = "The deployment environment name (prod, dev, etc.)"
  type = string
}

# Network Configuration
variable "vpc_id" {
  description = "The ID of the VPC where the RDS instance will be deployed"
  type = string
}

variable "subnet_ids" {
  description = "A list of private subnet IDs for the RDS subnet group"
  type = list(string)
}

variable "allowed_security_groups" {
  description = "A list of Security Group IDs (e.g., EKS nodes) allowed to connect to the database"
  type = list(string)
}

# Database Credentials

variable "db_name" {
  description = "The name of the default database to create"
  type = string
}

variable "db_username" {
  description = "Master username for the database administrator"
  type = string
}

variable "db_password" {
  description = "Master password for the database administrator (marked as sensitive)"
  type = string
  sensitive = true
}

# Security and Encryption (HIPAA Compliance)

variable "kms_key_arn" {
  description = "The ARN of the KMS key used for at-rest storage encryption"
  type = string
}

variable "storage_encrypted" {
  description = "Whether to enable storage encryption (required for HIPAA)"
  type = bool
  default = true
}

variable "deletion_protection" {
  description = "Protects the database from accidental deletion via Terraform"
  type = bool
  default = true
}

variable "iam_database_authentication_enabled" {
  description = "Enables IAM database authentication for centralized identity management"
  type        = bool
  default     = true
}

variable "copy_tags_to_snapshot" {
  description = "Whether to copy all instance tags to snapshots"
  type        = bool
  default     = true
}

# Instance and Storage Specifications
variable "engine_version" {
  description = "The version of the database engine to use (pinned for production stability)"
  type        = string
  default     = "18.1" # Update this once the environment is available
}

variable "instance_class" {
  description = "The compute and memory capacity of the RDS instance"
  type = string
  default = "db.r6g.large"
}

variable "allocated_storage" {
  description = "The amount of storage to allocate in gigabytes"
  type = number
  default = 500
}

variable "max_allocated_storage" {
  description = "The upper limit to which RDS can automatically scale the storage (0 to disable)"
  type        = number
  default     = 5000
}

variable "storage_type" {
  description = "The type of storage (gp3 is recommended for performance balance)"
  type = string
  default = "gp3"
}

# High Availability and Backups

variable "multi_az" {
  description = "Specifies if the RDS instance is multi-AZ for failover support"
  type = bool
  default = true
}

variable "backup_retention_period" {
  description = "The number of days to retain backups (HIPAA recommended: 35)"
  type = number
  default = 35
}

variable "backup_window" {
  description = "The daily time range (in UTC) during which automated backups are created"
  type        = string
  default     = "03:00-06:00"
}

variable "maintenance_window" {
  description = "The window to perform maintenance in (e.g., Mon:00:00-Mon:03:00)"
  type        = string
  default     = "Mon:00:00-Mon:03:00"
}

variable "auto_minor_version_upgrade" {
  description = "Indicates that minor engine upgrades will be applied automatically"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before the DB instance is deleted (set to false for Production)"
  type        = bool
  default     = false
}

# Monitoring and Performance

variable "performance_insights_enabled" {
  description = "Specifies whether Performance Insights are enabled"
  type        = bool
  default     = true
}

variable "performance_insights_retention_period" {
  description = "The amount of time in days to retain Performance Insights data"
  type        = number
  default     = 7
}

variable "monitoring_interval" {
  description = "The interval, in seconds, for Enhanced Monitoring metrics"
  type        = number
  default     = 60
}

variable "monitoring_role_arn" {
  description = "The ARN for the IAM role that permits RDS to send metrics to CloudWatch"
  type        = string
  default     = null
}

# Network and Connectivity

variable "network_type" {
  description = "Network stack type for the DB instance (IPV4 or DUAL for dual-stack)"
  type = string
  default = "DUAL"
}

variable "publicly_accessible" {
  description = "Controls if the database has a public IP address (always false for Production)"
  type = bool
  default = false
}