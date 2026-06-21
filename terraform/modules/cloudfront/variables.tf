variable "project_name" {
  type        = string
  description = "Project name"
}

variable "domain_name" {
  type        = string
  description = "The application domain name"
}

variable "certificate_arn" {
  type        = string
  description = "Validated ACM certificate ARN"
}

variable "waf_arn" {
  type        = string
  description = "WAFv2 Web ACL ARN"
}

variable "kms_key_arn" {
  type        = string
  description = "KMS Master Key ARN"
}

variable "nlb_dns_name" {
  type        = string
  description = "The DNS name of the Network Load Balancer created by Envoy Gateway"
  default     = "placeholder.example.com"
}

variable "cloudfront_secret_header" {
  type        = string
  description = "Secret origin validation header"
}
