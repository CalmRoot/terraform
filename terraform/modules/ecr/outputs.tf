output "repository_urls" {
  value = {
    frontend           = aws_ecr_repository.repos["frontend"].repository_url
    auth_service       = aws_ecr_repository.repos["auth-service"].repository_url
    assessment_service = aws_ecr_repository.repos["assessment-service"].repository_url
    therapist_service  = aws_ecr_repository.repos["therapist-service"].repository_url
  }
  description = "ECR Repository URLs"
}
