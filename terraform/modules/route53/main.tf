# Route53 Hosted Zone ONLY
# All DNS records are created in main.tf or acm module
# This avoids circular dependencies

resource "aws_route53_zone" "main" {
  name    = var.domain_name
  comment = "CalmRoot production hosted zone - managed by Terraform"

  tags = {
    Name        = "${var.project_name}-hosted-zone"
    Project     = var.project_name
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
