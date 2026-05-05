output "web_acl_arn" {
  value       = aws_wafv2_web_acl.main.arn
  description = "The ARN of the WAF Web ACL for ALB integration"
}