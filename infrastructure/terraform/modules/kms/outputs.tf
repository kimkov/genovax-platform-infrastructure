output "rds_key_arn" {
  value = aws_kms_key.rds.arn
}

output "eks_key_arn" {
  value = aws_kms_key.eks.arn
}

output "s3_key_arn"  {
  value = aws_kms_key.s3.arn
}

output "monitoring_key_arn" {
  value = aws_kms_key.monitoring.arn
}

output "ecr_key_arn" {
  description = "ARN of the KMS key for encryption of ECR images"
  value       = aws_kms_key.ecr.arn
}