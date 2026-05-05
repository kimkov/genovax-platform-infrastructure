output "kms_s3_key_arn" {
  description = "KMS Key ARN for S3 encryption"
  value       = module.kms.s3_key_arn
}

output "phi_bucket_name" {
  description = "S3 Bucket name for PHI data"
  value       = module.s3_medical_data.bucket_id
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = module.cognito.user_pool_id
}

output "cognito_client_id" {
  description = "Cognito Client ID"
  value       = module.cognito.user_pool_client_id
}

output "db_secret_arn" {
  description = "ARN of the DB password secret"
  value       = aws_secretsmanager_secret.db_password.arn
}