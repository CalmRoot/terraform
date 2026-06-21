# ==============================================================================
# AWS SES Email Identity for Operations Alerts
# ==============================================================================

resource "aws_ses_email_identity" "ops_email" {
  email = var.alert_email
}
