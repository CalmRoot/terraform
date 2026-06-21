# VPC Flow Logs — sends to unified logs S3 bucket
# The logs bucket is created in modules/s3/

resource "aws_s3_bucket" "unified_logs" {
  bucket        = "calmroot-logs-${var.aws_account_id}"
  force_destroy = true

  tags = {
    Name      = "calmroot-logs-${var.aws_account_id}"
    Purpose   = "Unified Logs Storage"
    ManagedBy = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "unified_logs" {
  bucket = aws_s3_bucket.unified_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "unified_logs" {
  bucket = aws_s3_bucket.unified_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "unified_logs" {
  bucket                  = aws_s3_bucket.unified_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "unified_logs" {
  bucket = aws_s3_bucket.unified_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSLogDeliveryWrite"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.unified_logs.arn}/vpc-flow-logs/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid    = "AWSLogDeliveryAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.unified_logs.arn
      }
    ]
  })
}

resource "aws_flow_log" "vpc" {
  log_destination      = "${aws_s3_bucket.unified_logs.arn}/vpc-flow-logs"
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = module.vpc.vpc_id

  tags = {
    Name      = "calmroot-vpc-flow-log"
    ManagedBy = "Terraform"
  }

  depends_on = [module.vpc]
}
