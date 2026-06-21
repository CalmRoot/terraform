variable "project_name" {
  type        = string
  description = "The name of the project"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
}

variable "aws_account_id" {
  type        = string
  description = "AWS Account ID"
}

variable "github_username" {
  type        = string
  description = "GitHub Username/Org name"
}

variable "github_repo" {
  type        = string
  description = "GitHub Repository name"
}
