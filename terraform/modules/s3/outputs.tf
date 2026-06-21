output "clinical_notes_bucket_name" {
  value       = aws_s3_bucket.clinical_notes.id
  description = "Name of the clinical notes bucket"
}

output "clinical_notes_bucket_arn" {
  value       = aws_s3_bucket.clinical_notes.arn
  description = "ARN of the clinical notes bucket"
}

output "exports_bucket_name" {
  value       = aws_s3_bucket.exports.id
  description = "Name of the exports bucket"
}

output "exports_bucket_arn" {
  value       = aws_s3_bucket.exports.arn
  description = "ARN of the exports bucket"
}
