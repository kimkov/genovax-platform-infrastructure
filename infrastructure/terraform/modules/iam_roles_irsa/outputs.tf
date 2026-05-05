output "lbc_role_arn" {
  description = "AWS Load Balancer Controller IAM Role ARN"
  value       = aws_iam_role.lbc.arn
}

output "secrets_store_csi_role_arn" {
  description = "Secrets Store CSI Driver IAM Role ARN"
  value       = aws_iam_role.secrets_store_csi.arn
}

output "velero_role_arn" {
  description = "Velero IAM Role ARN"
  value       = aws_iam_role.velero.arn
}

output "cluster_autoscaler_role_arn" {
  description = "Cluster Autoscaler IAM Role ARN"
  value       = aws_iam_role.cluster_autoscaler.arn
}

output "external_dns_role_arn" {
  description = "External DNS IAM Role ARN"
  value       = aws_iam_role.external_dns.arn
}

output "cert_manager_role_arn" {
  description = "Cert-Manager IAM Role ARN"
  value       = aws_iam_role.cert_manager.arn
}

output "phi_processor_role_arn" {
  description = "PHI Processor Application IAM Role ARN"
  value       = aws_iam_role.phi_processor.arn
}

output "fluent_bit_role_arn" {
  value = aws_iam_role.fluent_bit.arn
}
