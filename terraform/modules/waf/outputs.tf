output "web_acl_arn" {
  value       = aws_wafv2_web_acl.calmroot.arn
  description = "The ARN of the WAFv2 Web ACL"
}

output "web_acl_name" {
  value       = aws_wafv2_web_acl.calmroot.name
  description = "The name of the WAFv2 Web ACL"
}
