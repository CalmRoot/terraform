# Data Archives for Lambda Deployment
data "archive_file" "daily_export" {
  type        = "zip"
  source_dir  = "${path.module}/../../../lambda/dailyExport"
  output_path = "${path.module}/files/daily_export.zip"
}

data "archive_file" "alarm_notifier" {
  type        = "zip"
  source_dir  = "${path.module}/src/alarm_notifier"
  output_path = "${path.module}/files/alarm_notifier.zip"
}

# IAM Roles & Policies for Daily Export Lambda
resource "aws_iam_role" "daily_export" {
  name = "calmroot-${terraform.workspace}-daily-export-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "calmroot-${terraform.workspace}-daily-export-role"
  }
}

resource "aws_iam_role_policy" "daily_export" {
  name = "calmroot-${terraform.workspace}-daily-export-policy"
  role = aws_iam_role.daily_export.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # DynamoDB Access
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Scan",
          "dynamodb:Query"
        ]
        Resource = [
          "arn:aws:dynamodb:us-east-1:${var.aws_account_id}:table/calmroot-assessments",
          "arn:aws:dynamodb:us-east-1:${var.aws_account_id}:table/calmroot-mood-logs"
        ]
      },
      # S3 Access
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::calmroot-daily-exports",
          "arn:aws:s3:::calmroot-daily-exports/*"
        ]
      },
      # KMS Decrypt/GenerateDataKey Access
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = [var.kms_key_arn]
      },
      # CloudWatch Logs Basic Access
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:us-east-1:${var.aws_account_id}:log-group:/aws/lambda/calmroot-daily-export",
          "arn:aws:logs:us-east-1:${var.aws_account_id}:log-group:/aws/lambda/calmroot-daily-export:*"
        ]
      }
    ]
  })
}

# IAM Roles & Policies for Alarm Notifier Lambda
resource "aws_iam_role" "alarm_notifier" {
  name = "calmroot-${terraform.workspace}-alarm-notifier-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "calmroot-${terraform.workspace}-alarm-notifier-role"
  }
}

resource "aws_iam_role_policy" "alarm_notifier" {
  name = "calmroot-${terraform.workspace}-alarm-notifier-policy"
  role = aws_iam_role.alarm_notifier.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # SNS Publish Access
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = [var.sns_topic_arn]
      },
      # SES SendEmail Access
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
      },
      # KMS Decrypt Access
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = [var.kms_key_arn]
      },
      # CloudWatch Logs Basic Access
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:us-east-1:${var.aws_account_id}:log-group:/aws/lambda/calmroot-${terraform.workspace}-alarm-notifier",
          "arn:aws:logs:us-east-1:${var.aws_account_id}:log-group:/aws/lambda/calmroot-${terraform.workspace}-alarm-notifier:*"
        ]
      }
    ]
  })
}

# Lambda Functions

# 1. Daily Export Lambda
resource "aws_lambda_function" "daily_export" {
  function_name    = "calmroot-daily-export"
  role             = aws_iam_role.daily_export.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = data.archive_file.daily_export.output_path
  source_code_hash = data.archive_file.daily_export.output_base64sha256
  timeout          = 300
  memory_size      = 256

  environment {
    variables = {
      EXPORTS_BUCKET = "calmroot-daily-exports"
    }
  }

  tags = {
    Name = "calmroot-daily-export"
  }
}

# 2. Alarm Notifier Lambda
resource "aws_lambda_function" "alarm_notifier" {
  function_name    = "calmroot-${terraform.workspace}-alarm-notifier"
  role             = aws_iam_role.alarm_notifier.arn
  handler          = "index.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.alarm_notifier.output_path
  source_code_hash = data.archive_file.alarm_notifier.output_base64sha256
  timeout          = 60
  memory_size      = 128

  environment {
    variables = {
      SNS_TOPIC_ARN = var.sns_topic_arn
      OPS_EMAIL     = var.ops_email
      ENVIRONMENT   = terraform.workspace
    }
  }

  tags = {
    Name = "calmroot-${terraform.workspace}-alarm-notifier"
  }
}

# EventBridge Rules & Triggers (Daily at Midnight UTC)
resource "aws_cloudwatch_event_rule" "daily_export" {
  name                = "calmroot-${terraform.workspace}-daily-export-trigger"
  description         = "Trigger daily assessments and mood logs S3 export at midnight UTC"
  schedule_expression = "cron(0 0 * * ? *)"

  tags = {
    Name = "calmroot-${terraform.workspace}-daily-export-trigger"
  }
}

resource "aws_cloudwatch_event_target" "daily_export" {
  rule      = aws_cloudwatch_event_rule.daily_export.name
  target_id = "TriggerDailyExportLambda"
  arn       = aws_lambda_function.daily_export.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.daily_export.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_export.arn
}

# SNS Invocation Permission for Alarm Notifier
resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alarm_notifier.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = var.sns_topic_arn
}

resource "aws_sns_topic_subscription" "alarm_notifier" {
  topic_arn = var.sns_topic_arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.alarm_notifier.arn
}
