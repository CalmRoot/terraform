output "eks_cluster_name" {
  value       = module.eks.cluster_name
  description = "Name of the EKS cluster"
}

output "eks_cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "EKS API server endpoint URL"
}

output "ecr_repository_urls" {
  value       = module.ecr.repository_urls
  description = "Map of ECR repository names to URLs"
}

output "ecr_urls" {
  value       = module.ecr.repository_urls
  description = "Alias for Map of ECR repository names to URLs"
}

output "kms_key_arn" {
  value       = module.security.kms_key_arn
  description = "Master KMS encryption Key ARN"
}

output "secrets_manager_jwt_arn" {
  value       = module.secrets.jwt_secret_arn
  description = "Secrets Manager JWT Secret ARN"
}

output "secrets_manager_ses_arn" {
  value       = module.secrets.ses_secret_arn
  description = "Secrets Manager SES Secret ARN"
}

output "github_actions_role_arn" {
  value       = module.security.github_actions_role_arn
  description = "IAM Role ARN for GitHub Actions deployment integration"
}

# --- CloudFront & DNS outputs ---
output "cloudfront_distribution_id" {
  value       = module.cloudfront.distribution_id
  description = "The CloudFront Distribution ID"
}

output "cloudfront_domain" {
  value       = module.cloudfront.distribution_domain_name
  description = "CloudFront Distribution Domain Name"
}

output "cloudfront_domain_name" {
  value       = module.cloudfront.distribution_domain_name
  description = "CloudFront Distribution Domain Name"
}

output "cloudfront_hosted_zone_id" {
  value       = module.cloudfront.distribution_hosted_zone_id
  description = "CloudFront Distribution Hosted Zone ID"
}

output "route53_nameservers" {
  value       = module.route53.nameservers
  description = "Name servers associated with the new hosted zone"
}

# --- IRSA Roles outputs ---
output "auth_service_role_arn" {
  value       = module.eks.auth_service_role_arn
  description = "IAM Role ARN for auth-service IRSA"
}

output "assessment_service_role_arn" {
  value       = module.eks.assessment_service_role_arn
  description = "IAM Role ARN for assessment-service IRSA"
}

output "therapist_service_role_arn" {
  value       = module.eks.therapist_service_role_arn
  description = "IAM Role ARN for therapist-service IRSA"
}

output "aws_lb_controller_role_arn" {
  value       = module.eks.aws_lb_controller_role_arn
  description = "IAM Role ARN for AWS LB Controller IRSA"
}

output "external_secrets_role_arn" {
  value       = module.eks.external_secrets_role_arn
  description = "IAM Role ARN for External Secrets Operator IRSA"
}

output "argocd_role_arn" {
  value       = module.eks.argocd_role_arn
  description = "IAM Role ARN for ArgoCD Application Controller IRSA"
}

output "action_required" {
  value = <<-EOT
  ╔══════════════════════════════════════════════════╗
  ║   ⚠️  ACTION REQUIRED — UPDATE NAMESERVERS      ║
  ╠══════════════════════════════════════════════════╣
  ║  Add these to your domain registrar:            ║
  ║  ${module.route53.nameservers[0]}               ║
  ║  ${module.route53.nameservers[1]}               ║
  ║  ${module.route53.nameservers[2]}               ║
  ║  ${module.route53.nameservers[3]}               ║
  ╚══════════════════════════════════════════════════╝
  EOT
  description = "Instructions for manual domain delegation setup"
}

output "bastion_instance_id" {
  description = "Bastion host instance ID"
  value       = module.bastion.bastion_instance_id
}

output "bastion_connect_command" {
  description = "Command to connect to bastion host via SSM"
  value       = module.bastion.connect_command
}

output "k8s_namespace" {
  description = "Kubernetes production namespace"
  value       = var.k8s_namespace
}

output "cluster_autoscaler_role_arn" {
  description = "IAM role ARN for cluster autoscaler"
  value       = module.eks.cluster_autoscaler_role_arn
}

output "daily_export_lambda_arn" {
  description = "The ARN of the Daily Export Lambda function"
  value       = module.lambda.daily_export_lambda_arn
}

output "alarm_notifier_lambda_arn" {
  description = "The ARN of the Alarm Notifier Lambda function"
  value       = module.lambda.alarm_notifier_lambda_arn
}

