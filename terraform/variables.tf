variable "aws_account_id" {
  type        = string
  description = "The AWS Account ID"
  default     = "006805625766"
}

variable "aws_region" {
  type        = string
  description = "The AWS Region"
  default     = "us-east-1"
}

variable "project_name" {
  type        = string
  description = "The name of the project"
  default     = "calmroot"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR range for the VPC"
  default     = "10.0.0.0/16"
}

variable "github_username" {
  type        = string
  description = "The GitHub username or org name"
  default     = "CalmRoot"
}

variable "github_repo" {
  type        = string
  description = "The GitHub repository name"
  default     = "CalmRoot"
}

variable "alert_email" {
  type        = string
  description = "Email address for CloudWatch metric alert notifications"
  default     = "bharath70135@gmail.com"
}

# --- CloudFront & Domain configurations ---
variable "domain_name" {
  type        = string
  description = "The application domain name"
  default     = "calmroot-project.online"
}

variable "nlb_dns_name" {
  type        = string
  description = "The DNS name of the Network Load Balancer created by Envoy Gateway"
  default     = "placeholder.example.com"
}

variable "cloudfront_secret_header" {
  type        = string
  description = "A random/secret header value to prevent direct traffic bypassing CloudFront"
  default     = "calmroot-prod-secret-header-123456"
}

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "production"
}

variable "owner" {
  type        = string
  description = "Owner of the resources"
  default     = "CalmRoot-DevOps"
}

variable "eks_cluster_version" {
  type        = string
  description = "Kubernetes version for EKS cluster"
  default     = "1.31"
}

variable "eks_node_instance_type" {
  type        = string
  description = "EC2 instance type for EKS worker nodes"
  default     = "t3.medium"
}

variable "eks_node_min_size" {
  type        = number
  description = "Minimum number of EKS worker nodes"
  default     = 2
}

variable "eks_node_max_size" {
  type        = number
  description = "Maximum number of EKS worker nodes"
  default     = 4
}

variable "eks_node_desired_size" {
  type        = number
  description = "Desired number of EKS worker nodes"
  default     = 2
}

variable "bastion_instance_type" {
  type        = string
  description = "EC2 instance type for bastion host"
  default     = "t3.micro"
}

variable "k8s_namespace" {
  type        = string
  description = "Kubernetes namespace for production workloads"
  default     = "production"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for public subnets"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private subnets"
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}
