variable "project_name" {
  type        = string
  description = "The name of the project"
}

variable "kms_key_arn" {
  type        = string
  description = "KMS Master Key ARN"
}

variable "alert_email" {
  type        = string
  description = "The email address for alerts"
}

variable "eks_cluster_name" {
  type        = string
  description = "The EKS cluster name"
}

variable "cloudfront_distribution_id" {
  type        = string
  description = "The CloudFront Distribution ID"
}

variable "waf_web_acl_name" {
  type        = string
  description = "The name of the WAFv2 Web ACL"
}
