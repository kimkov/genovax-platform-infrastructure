output "db_instance_endpoint" {
  description = "RDS instance connection endpoint"
  value       = aws_db_instance.primary.endpoint
}

output "db_instance_identifier" {
  description = "RDS instance ID"
  value       = aws_db_instance.primary.identifier
}

output "db_instance_arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.primary.arn
}

output "db_instance_resource_id" {
  description = "RDS instance resource ID"
  value       = aws_db_instance.primary.resource_id
}