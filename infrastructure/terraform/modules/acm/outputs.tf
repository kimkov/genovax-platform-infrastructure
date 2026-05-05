output "certificate_arn" {
  description = "ARN of a verified and ready-to-use certificate"
  value       = aws_acm_certificate_validation.this.certificate_arn
}

output "certificate_domain" {
  description = "Main domain of the certificate"
  value       = aws_acm_certificate.this.domain_name
}