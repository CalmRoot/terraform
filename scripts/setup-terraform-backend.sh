#!/usr/bin/env bash
# setup-terraform-backend.sh
# Creates the S3 bucket and DynamoDB lock table for Terraform backend storage.
# This script is meant to be run once manually before initial terraform setup.

set -euo pipefail

# Disable AWS CLI interactive paging
export AWS_PAGER=""

AWS_REGION="us-east-1"
S3_BUCKET_NAME="calmroot-terraform-state"
DYNAMODB_TABLE_NAME="calmroot-terraform-locks"

echo "Initializing CalmRoot Terraform backend resources..."

# 1. Create S3 State Bucket (with private settings, versioning, and encryption)
if aws s3api head-bucket --bucket "$S3_BUCKET_NAME" 2>/dev/null; then
    echo "S3 state bucket '$S3_BUCKET_NAME' already exists. Skipping creation."
else
    echo "Creating S3 state bucket '$S3_BUCKET_NAME'..."
    aws s3api create-bucket \
        --bucket "$S3_BUCKET_NAME" \
        --region "$AWS_REGION"
    
    echo "Enabling versioning on bucket '$S3_BUCKET_NAME'..."
    aws s3api put-bucket-versioning \
        --bucket "$S3_BUCKET_NAME" \
        --versioning-configuration Status=Enabled

    echo "Applying public access block to bucket '$S3_BUCKET_NAME'..."
    aws s3api put-public-access-block \
        --bucket "$S3_BUCKET_NAME" \
        --public-access-block-configuration \
            BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

    echo "Enabling default server-side encryption..."
    aws s3api put-bucket-encryption \
        --bucket "$S3_BUCKET_NAME" \
        --server-side-encryption-configuration '{
            "Rules": [
                {
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }
            ]
        }'
fi

# 2. Create DynamoDB Lock Table (PK must be LockID (S))
if aws dynamodb describe-table --table-name "$DYNAMODB_TABLE_NAME" --region "$AWS_REGION" >/dev/null 2>&1; then
    echo "DynamoDB lock table '$DYNAMODB_TABLE_NAME' already exists. Skipping creation."
else
    echo "Creating DynamoDB locking table '$DYNAMODB_TABLE_NAME'..."
    aws dynamodb create-table \
        --table-name "$DYNAMODB_TABLE_NAME" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "$AWS_REGION"
    
    echo "Waiting for table creation to complete..."
    aws dynamodb wait table-exists --table-name "$DYNAMODB_TABLE_NAME" --region "$AWS_REGION"
fi

echo "Terraform backend resources successfully configured!"
echo "Bucket Name: $S3_BUCKET_NAME"
echo "DynamoDB Table Name: $DYNAMODB_TABLE_NAME"
