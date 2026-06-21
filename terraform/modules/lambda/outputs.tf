output "daily_export_lambda_arn" {
  description = "The ARN of the Daily Export Lambda function"
  value       = aws_lambda_function.daily_export.arn
}

output "alarm_notifier_lambda_arn" {
  description = "The ARN of the Alarm Notifier Lambda function"
  value       = aws_lambda_function.alarm_notifier.arn
}
