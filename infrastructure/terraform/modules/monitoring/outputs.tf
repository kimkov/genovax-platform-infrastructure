output "cloudtrail_logs_bucket_arn" {
  value       = aws_s3_bucket.cloudtrail_logs.arn
  description = "ARN of the bucket for infrastructure logs"
}

output "cloudtrail_logs_bucket_id" {
  value       = aws_s3_bucket.cloudtrail_logs.id
  description = "ID of the bucket for infrastructure logs"
}

output "eks_container_log_group_name" {
  value       = aws_cloudwatch_log_group.eks_container_logs.name
  description = "The name of the CloudWatch Log Group for EKS container logs"
}