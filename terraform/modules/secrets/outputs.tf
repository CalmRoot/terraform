output "jwt_secret_name" {
  value       = aws_secretsmanager_secret.jwt.name
  description = "Name of the JWT secret"
}

output "jwt_secret_arn" {
  value       = aws_secretsmanager_secret.jwt.arn
  description = "ARN of the JWT secret"
}

output "ses_secret_name" {
  value       = aws_secretsmanager_secret.ses.name
  description = "Name of the SES secret"
}

output "ses_secret_arn" {
  value       = aws_secretsmanager_secret.ses.arn
  description = "ARN of the SES secret"
}
