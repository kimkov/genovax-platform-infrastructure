terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# Requesting an SSL/TLS certificate
resource "aws_acm_certificate" "this" {
  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = "DNS"

  tags = merge(var.common_tags, {
    Name = "${var.env}-${var.domain_name}-cert"
  })

  # Generate a new certificate before deleting the old one.
  # This prevents TLS connections from being broken when updating resources.
  lifecycle {
    create_before_destroy = true
  }
}

# Automatic creation of DNS records for validation (Validation Records).
# A dynamic loop is used to support all names in the certificate.
resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.zone_id
}

# Certificate Validation Pending Resource Ensures that Terraform does not continue any work (such as creating an ALB)
# until the certificate status is 'ISSUED'.
resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}