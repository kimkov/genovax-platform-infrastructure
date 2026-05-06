output "route53_zone_id" {
  description = "Root DNS zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "github_actions_role_arn" {
  description = "ARN roles for GitHub Actions"
  value       = aws_iam_role.github_actions.arn
}

output "permission_boundary_arn" {
  description = "ARN of the standard permission boundary policy"
  value       = aws_iam_policy.standard_boundary.arn
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC Provider"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "audit_logs_bucket_arn" {
  description = "ARN of the audit log bucket"
  value       = aws_s3_bucket.audit_logs.arn
}

output "kms_state_key_arn" {
  description = "ARN of the KMS key for state encryption"
  value       = aws_kms_key.terraform_state.arn
}

output "access_analyzer_arn" {
  description = "ARN of the IAM Access Analyzer"
  value       = aws_accessanalyzer_analyzer.main.arn
}

output "sso_permission_sets" {
  description = "Map of SSO Permission Set ARNs"
  value       = { for k, v in aws_ssoadmin_permission_set.sets : k => v.arn }
}