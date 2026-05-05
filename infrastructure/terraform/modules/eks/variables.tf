variable "env" {
  description = "The deployment environment name (prod, dev, etc.)"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "vpc_id" {
  description = "ID VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "kms_key_arn" {
  description = "ARN KMS encryption key"
  type        = string
}

variable "kubernetes_networking_config" {
  description = "Kubernetes network settings (e.g. IPv6)"
  type        = any
  default     = {}
}

variable "node_groups" {
  description = "Configuration of managed node groups"
  type        = any
  default     = {}
}

variable "fargate_profiles" {
  description = "Fargate Profile Configuration"
  type        = any
  default     = {}
}