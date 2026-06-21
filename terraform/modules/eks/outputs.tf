output "cluster_name" {
  value       = aws_eks_cluster.main.name
  description = "EKS Cluster Name"
}

output "cluster_endpoint" {
  value       = aws_eks_cluster.main.endpoint
  description = "EKS API Endpoint"
}

output "cluster_security_group_id" {
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  description = "Cluster Security Group ID"
}

output "auth_service_role_arn" {
  value       = aws_iam_role.auth_service.arn
  description = "ARN of auth-service IRSA role"
}

output "assessment_service_role_arn" {
  value       = aws_iam_role.assessment_service.arn
  description = "ARN of assessment-service IRSA role"
}

output "therapist_service_role_arn" {
  value       = aws_iam_role.therapist_service.arn
  description = "ARN of therapist-service IRSA role"
}

output "aws_lb_controller_role_arn" {
  value       = aws_iam_role.aws_lb_controller.arn
  description = "ARN of AWS LB Controller IRSA role"
}

output "external_secrets_role_arn" {
  value       = aws_iam_role.external_secrets.arn
  description = "ARN of External Secrets Operator IRSA role"
}

output "argocd_role_arn" {
  value       = aws_iam_role.argocd.arn
  description = "ARN of ArgoCD application controller IRSA role"
}

output "cluster_autoscaler_role_arn" {
  description = "IAM role ARN for cluster autoscaler"
  value       = aws_iam_role.cluster_autoscaler.arn
}
