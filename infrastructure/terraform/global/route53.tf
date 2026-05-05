resource "aws_route53_zone" "main" {
  name = var.domain_name
  comment = "The main public area for the project ${var.project_name}"
  tags = var.common_tags
}