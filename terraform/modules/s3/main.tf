# S3 Buckets Configuration

# 1. Clinical Notes Bucket
resource "aws_s3_bucket" "clinical_notes" {
  bucket        = "calmroot-clinical-notes"
  force_destroy = true

  tags = {
    Name        = "${var.project_name}-clinical-notes"
    Project     = "calmroot"
    Environment = "production"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Encryption configuration for clinical notes bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "clinical_notes" {
  bucket = aws_s3_bucket.clinical_notes.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# Versioning configuration for clinical notes bucket
resource "aws_s3_bucket_versioning" "clinical_notes" {
  bucket = aws_s3_bucket.clinical_notes.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Block public access to clinical notes bucket
resource "aws_s3_bucket_public_access_block" "clinical_notes" {
  bucket                  = aws_s3_bucket.clinical_notes.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 2. Daily Exports Bucket
resource "aws_s3_bucket" "exports" {
  bucket        = "calmroot-daily-exports"
  force_destroy = true

  tags = {
    Name        = "${var.project_name}-daily-exports"
    Project     = "calmroot"
    Environment = "production"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Encryption configuration for exports bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "exports" {
  bucket = aws_s3_bucket.exports.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# Versioning configuration for exports bucket
resource "aws_s3_bucket_versioning" "exports" {
  bucket = aws_s3_bucket.exports.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Block public access to exports bucket
resource "aws_s3_bucket_public_access_block" "exports" {
  bucket                  = aws_s3_bucket.exports.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle Configuration (Transition to IA after 90 days)
resource "aws_s3_bucket_lifecycle_configuration" "exports" {
  bucket = aws_s3_bucket.exports.id

  rule {
    id     = "transition-to-infrequent-access"
    status = "Enabled"
    filter {}

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }
  }
}
