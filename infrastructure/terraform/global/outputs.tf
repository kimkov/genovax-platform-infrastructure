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

output "iam_group_architects_arn" {
  description = "ARN of the Architects IAM group"
  value = aws_iam_group.architects.arn
}

output "iam_group_developers_arn" {
  description = "ARN of the Developers IAM group"
  value = aws_iam_group.developers.arn
}

output "office365_saml_provider_arn" {
  description = "ARN of the Office 365 SAML Identity Provider"
  value       = length(aws_iam_saml_provider.office365) > 0 ? aws_iam_saml_provider.office365[0].arn : null
}

output "federated_admin_role_arn" {
  description = "ARN of the Federated Admin Role (Azure AD)"
  value       = length(aws_iam_role.federated_admin) > 0 ? aws_iam_role.federated_admin[0].arn : null
}