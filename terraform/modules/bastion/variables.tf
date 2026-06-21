variable "project_name" {
  type        = string
  description = "Project name"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where bastion will be deployed"
}

variable "public_subnet_id" {
  type        = string
  description = "Public subnet ID for bastion host"
}

variable "bastion_instance_type" {
  type        = string
  description = "EC2 instance type for bastion"
  default     = "t3.micro"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name for kubeconfig setup"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}
