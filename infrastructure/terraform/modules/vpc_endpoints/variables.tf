variable "env" {
  description = "Name of the deployment environment (prod, dev, etc.)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC in which the endpoints will be created"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block for Security Group configuration"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for placing interface endpoints"
  type        = list(string)
}

variable "route_table_ids" {
  description = "List of routing table IDs for Gateway endpoints (S3, DynamoDB)"
  type        = list(string)
}

variable "common_tags" {
  description = "General tags for all resources"
  type        = map(string)
}
