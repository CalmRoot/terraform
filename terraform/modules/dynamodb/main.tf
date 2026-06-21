# DynamoDB Resources Configuration

# 1. users table
resource "aws_dynamodb_table" "users" {
  name         = "calmroot-users"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  range_key    = "SK"

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  attribute {
    name = "email"
    type = "S"
  }

  global_secondary_index {
    name            = "email-index"
    hash_key        = "email"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  tags = {
    Name        = "calmroot-users"
    Project     = "calmroot"
    Environment = "production"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# 2. sessions table
resource "aws_dynamodb_table" "sessions" {
  name         = "calmroot-sessions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "sessionId"
  range_key    = "SK"

  attribute {
    name = "sessionId"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  attribute {
    name = "therapistId"
    type = "S"
  }

  attribute {
    name = "userId"
    type = "S"
  }

  global_secondary_index {
    name            = "therapist-index"
    hash_key        = "therapistId"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "patient-index"
    hash_key        = "userId"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  tags = {
    Name        = "calmroot-sessions"
    Project     = "calmroot"
    Environment = "production"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# 3. assessment templates table
resource "aws_dynamodb_table" "assessment_templates" {
  name         = "calmroot-assessment-templates"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "type"
  range_key    = "SK"

  attribute {
    name = "type"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  tags = {
    Name        = "calmroot-assessment-templates"
    Project     = "calmroot"
    Environment = "production"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# 4. assessments table
resource "aws_dynamodb_table" "assessments" {
  name         = "calmroot-assessments"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  range_key    = "SK"

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  tags = {
    Name        = "calmroot-assessments"
    Project     = "calmroot"
    Environment = "production"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# 5. mood logs table
resource "aws_dynamodb_table" "mood_logs" {
  name         = "calmroot-mood-logs"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  range_key    = "SK"

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  tags = {
    Name        = "calmroot-mood-logs"
    Project     = "calmroot"
    Environment = "production"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# 6. therapist patients table
resource "aws_dynamodb_table" "therapist_patients" {
  name         = "calmroot-therapist-patients"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "therapistId"
  range_key    = "SK"

  attribute {
    name = "therapistId"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  tags = {
    Name        = "calmroot-therapist-patients"
    Project     = "calmroot"
    Environment = "production"
  }

  lifecycle {
    prevent_destroy = true
  }
}
