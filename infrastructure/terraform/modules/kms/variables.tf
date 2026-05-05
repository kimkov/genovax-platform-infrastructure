variable "env" {
  description = "The deployment environment name (prod, dev, etc.)"
  type = string
}

variable "common_tags" {
  type    = map(string)
  default = {}
}

variable "s3_replication_role_arn" {
  type    = string
  default = null
}

variable "eks_node_role_arn" {
  type    = string
  default = null
}

variable "ecr_allowed_read_principals" {
  description = "List of ARNs of roles or wildcards that are allowed to decrypt ECR images"
  type        = list(string)
  default     = []
}