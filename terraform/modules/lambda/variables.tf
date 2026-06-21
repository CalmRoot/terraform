variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
}

variable "aws_account_id" {
  description = "AWS Account ID for resources"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS Customer Managed Key ARN for encryption and decryption"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS Topic ARN for publishing the formatted HTML emails"
  type        = string
}

variable "ops_email" {
  description = "Operations email address for AWS SES sender/receiver"
  type        = string
}

