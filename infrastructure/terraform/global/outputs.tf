output "route53_zone_id" {
  description = "Root DNS zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "github_actions_role_arn" {
  description = "ARN roles for GitHub Actions"
  value       = aws_iam_role.github_actions.arn
}

output "audit_logs_bucket_arn" {
  description = "ARN of the audit log bucket"
  value       = aws_s3_bucket.audit_logs.arn
}

output "kms_state_key_arn" {
  description = "ARN of the KMS key for state encryption"
  value       = aws_kms_key.terraform_state.arn
}