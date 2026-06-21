output "zone_id" {
  value       = aws_route53_zone.main.zone_id
  description = "Route 53 hosted zone ID"
}

output "zone_name" {
  value       = aws_route53_zone.main.name
  description = "Route 53 hosted zone name"
}

output "nameservers" {
  value       = aws_route53_zone.main.name_servers
  description = "4 nameservers - add these to your domain registrar"
}
