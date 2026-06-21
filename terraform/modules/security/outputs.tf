output "kms_key_arn" {
  value       = aws_kms_key.master.arn
  description = "The ARN of the KMS Master Key"
}

output "github_actions_role_arn" {
  value       = data.aws_iam_role.github_actions.arn
  description = "The ARN of the GitHub Actions OIDC deployment IAM role"
}

output "eks_cluster_sg_id" {
  value       = aws_security_group.eks_cluster.id
  description = "Security Group ID of EKS Cluster"
}

output "eks_nodes_sg_id" {
  value       = aws_security_group.eks_nodes.id
  description = "Security Group ID of EKS Worker Nodes"
}

output "alb_sg_id" {
  value       = aws_security_group.alb.id
  description = "Security Group ID of Application Load Balancer"
}
