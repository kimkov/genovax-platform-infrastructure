output "bucket_id" {
  description = "The name of the primary bucket"
  value       = aws_s3_bucket.medical_data.id
}

output "bucket_arn" {
  description = "The ARN of the primary bucket"
  value       = aws_s3_bucket.medical_data.arn
}

output "replication_bucket_arn" {
  description = "The ARN of the replication (DR) bucket"
  value       = aws_s3_bucket.replication_dest.arn
}

output "replication_role_name" {
  description = "The name of the IAM role used for replication"
  value       = aws_iam_role.replication.name
}
