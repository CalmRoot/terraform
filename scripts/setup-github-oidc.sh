#!/usr/bin/env bash
# setup-github-oidc.sh
# Registers the GitHub OIDC Identity Provider in IAM and provisions the GitHub Actions deploy role.
# Run once manually before configuring your GitHub repository secrets.

set -euo pipefail

# Disable AWS CLI interactive paging
export AWS_PAGER=""

AWS_ACCOUNT_ID="006805625766"
AWS_REGION="us-east-1"
ROLE_NAME="calmroot-github-actions-role"
GITHUB_REPO="Bharath-1602/CalmRoot"

echo "Setting up GitHub Actions OIDC federation..."

# 1. Register GitHub OIDC Identity Provider (if not already existing)
PROVIDER_ARN="arn:aws:iam::$AWS_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"

if aws iam get-open-id-connect-provider --open-id-connect-provider-arn "$PROVIDER_ARN" >/dev/null 2>&1; then
    echo "OIDC provider for GitHub already exists. Skipping creation."
else
    echo "Creating OIDC Provider for GitHub Actions..."
    aws iam create-open-id-connect-provider \
        --url "https://token.actions.githubusercontent.com" \
        --client-id-list "sts.amazonaws.com" \
        --thumbprint-list "696581457d58066b4b002eb10f0c37b35d0c3ddf"
fi

# 2. Create GitHub Actions IAM trust policy JSON file
TRUST_POLICY_FILE="trust-policy-temp.json"
cat <<EOF > "$TRUST_POLICY_FILE"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:${GITHUB_REPO}:*"
        }
      }
    }
  ]
}
EOF

# 3. Create IAM Role
if aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
    echo "IAM Role '$ROLE_NAME' already exists. Updating trust policy..."
    aws iam update-assume-role-policy \
        --role-name "$ROLE_NAME" \
        --policy-document "file://$TRUST_POLICY_FILE"
else
    echo "Creating IAM Role '$ROLE_NAME'..."
    aws iam create-role \
        --role-name "$ROLE_NAME" \
        --assume-role-policy-document "file://$TRUST_POLICY_FILE" \
        --description "CalmRoot EKS deployment role for GitHub Actions pipelines"
fi

# 4. Attach policy (AdministratorAccess for simplicity in dev account)
echo "Attaching AdministratorAccess policy to role '$ROLE_NAME'..."
aws iam attach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn "arn:aws:iam::aws:policy/AdministratorAccess"

rm -f "$TRUST_POLICY_FILE"

echo "GitHub Actions OIDC setup complete!"
echo "Role ARN: arn:aws:iam::$AWS_ACCOUNT_ID:role/$ROLE_NAME"
echo "Please add the following variables/secrets to your GitHub repository settings:"
echo "  AWS_ROLE_ARN: arn:aws:iam::$AWS_ACCOUNT_ID:role/$ROLE_NAME"
echo "  AWS_REGION: $AWS_REGION"
echo "  AWS_ACCOUNT_ID: $AWS_ACCOUNT_ID"
