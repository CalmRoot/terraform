output "distribution_id" {
  value       = aws_cloudfront_distribution.main.id
  description = "The CloudFront Distribution ID"
}

output "distribution_domain_name" {
  value       = aws_cloudfront_distribution.main.domain_name
  description = "The CloudFront Distribution Domain Name"
}

output "distribution_hosted_zone_id" {
  value       = aws_cloudfront_distribution.main.hosted_zone_id
  description = "The CloudFront Distribution Hosted Zone ID (Z2FDTNDATAQYW2)"
}
