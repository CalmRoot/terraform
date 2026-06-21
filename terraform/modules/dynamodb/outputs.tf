output "users_table_arn" {
  value       = aws_dynamodb_table.users.arn
  description = "ARN of the users table"
}

output "sessions_table_arn" {
  value       = aws_dynamodb_table.sessions.arn
  description = "ARN of the sessions table"
}

output "assessment_templates_table_arn" {
  value       = aws_dynamodb_table.assessment_templates.arn
  description = "ARN of the templates table"
}

output "assessments_table_arn" {
  value       = aws_dynamodb_table.assessments.arn
  description = "ARN of the assessments table"
}

output "mood_logs_table_arn" {
  value       = aws_dynamodb_table.mood_logs.arn
  description = "ARN of the mood logs table"
}

output "therapist_patients_table_arn" {
  value       = aws_dynamodb_table.therapist_patients.arn
  description = "ARN of the therapist patients table"
}
