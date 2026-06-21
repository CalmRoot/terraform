#!/usr/bin/env bash
# scripts/update-secrets.sh
# Prompts for and updates Secrets Manager credentials for the CalmRoot production environment.
# After updating, it triggers a rollout restart of the External Secrets Operator to sync them.

set -euo pipefail

# Disable AWS CLI interactive paging
export AWS_PAGER=""

AWS_REGION="us-east-1"

echo "=================================================================="
echo "🔐 Update CalmRoot Production Secrets in AWS Secrets Manager"
echo "=================================================================="

# 1. Prompt for inputs
read -rsp "Enter JWT_SECRET: " JWT_SECRET
echo ""
read -rp "Enter SES_SENDER_EMAIL (Gmail address): " SES_SENDER_EMAIL
read -rp "Enter SMTP_PASSWORD (Gmail App Password): " SMTP_PASS

SMTP_HOST="smtp.gmail.com"
SMTP_PORT="587"
SMTP_USER="$SES_SENDER_EMAIL"
SMTP_FROM="$SES_SENDER_EMAIL"

# 2. Update calmroot/prod/jwt
echo "Updating JWT Secret 'calmroot/prod/jwt'..."
aws secretsmanager put-secret-value \
    --secret-id "calmroot/prod/jwt" \
    --secret-string "{\"JWT_SECRET\":\"$JWT_SECRET\"}" \
    --region "$AWS_REGION"

# 3. Update calmroot/prod/ses
echo "Updating SES & SMTP Secrets 'calmroot/prod/ses'..."
aws secretsmanager put-secret-value \
    --secret-id "calmroot/prod/ses" \
    --secret-string "{\"SES_SENDER_EMAIL\":\"$SES_SENDER_EMAIL\",\"SMTP_HOST\":\"$SMTP_HOST\",\"SMTP_PORT\":\"$SMTP_PORT\",\"SMTP_USER\":\"$SMTP_USER\",\"SMTP_PASS\":\"$SMTP_PASS\",\"SMTP_FROM\":\"$SMTP_FROM\"}" \
    --region "$AWS_REGION"

# 4. Restart External Secrets Operator
echo "Restarting External Secrets Operator to trigger immediate secrets sync..."
kubectl rollout restart deployment/external-secrets -n external-secrets || echo "Failed to restart ESO, operator may not be running yet."

echo "=================================================================="
echo "✅ Secrets successfully updated and sync triggered!"
echo "=================================================================="
