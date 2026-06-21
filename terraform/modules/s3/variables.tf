variable "project_name" {
  type        = string
  description = "The name of the project"
}

variable "kms_key_arn" {
  type        = string
  description = "KMS Master Key ARN"
}
