output "vpc_endpoint_security_group_id" {
  description = "ID Security Group for VPC Endpoints"
  value       = aws_security_group.vpc_endpoints.id
}

output "interface_endpoints" {
  description = "Map of created interface endpoints"
  value       = aws_vpc_endpoint.interface_endpoints
}
