# AWS Secrets Manager Configurations

# 1. JWT Secret Definition
resource "aws_secretsmanager_secret" "jwt" {
  name                    = "calmroot/prod/jwt"
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = 0 # Force delete on destroy for dev convenience

  tags = {
    Name = "${var.project_name}-jwt-secret"
  }
}

resource "aws_secretsmanager_secret_version" "jwt_placeholder" {
  secret_id = aws_secretsmanager_secret.jwt.id
  secret_string = jsonencode({
    JWT_SECRET = "CHANGE-ME-AFTER-CREATION"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# 2. SES Secret Definition
resource "aws_secretsmanager_secret" "ses" {
  name                    = "calmroot/prod/ses"
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = 0

  tags = {
    Name = "${var.project_name}-ses-secret"
  }
}

resource "aws_secretsmanager_secret_version" "ses_placeholder" {
  secret_id = aws_secretsmanager_secret.ses.id
  secret_string = jsonencode({
    SES_SENDER_EMAIL = "CHANGE-ME-AFTER-CREATION"
    SMTP_HOST        = "CHANGE-ME-AFTER-CREATION"
    SMTP_PORT        = "587"
    SMTP_USER        = "CHANGE-ME-AFTER-CREATION"
    SMTP_PASS        = "CHANGE-ME-AFTER-CREATION"
    SMTP_FROM        = "CHANGE-ME-AFTER-CREATION"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}
