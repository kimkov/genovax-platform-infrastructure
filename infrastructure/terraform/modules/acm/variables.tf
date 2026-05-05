variable domain_name {
  description = "Primary domain name"
  type = string
}

variable "subject_alternative_names" {
  description = "Subscript Name (SAN) list, such as ['*.example.com']"
  type        = list(string)
  default     = []
}

variable "zone_id" {
  description = "Route53 Zone ID for automatic domain ownership verification"
  type        = string
}

variable "env" {
  description = "The deployment environment name (prod, dev, etc.)"
  type        = string
}

variable "common_tags" {
  description = "General tags for compliance and cost accounting"
  type        = map(string)
  default     = {}
}