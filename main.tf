# Configure the AWS provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-2"
}

# S3 Bucket for file uploads
resource "aws_s3_bucket" "upload_bucket" {
  bucket        = var.file_upload_bucket
  force_destroy = true

}

# SNS Topic for file upload notifications
resource "aws_sns_topic" "sns_topic" {
  name = "s3-file-upload-notification-topic"
}

# SNS Subscription for email notifications
resource "aws_sns_topic_subscription" "sns_subscription" {
  topic_arn = aws_sns_topic.sns_topic.arn
  protocol  = "email"
  endpoint  = var.email_subscription_endpoint
}

# SQS Queue for file upload notifications
resource "aws_sqs_queue" "sqs_queue" {
  name                       = "s3-notification-queue"
  delay_seconds              = 0
  max_message_size           = 262144
  message_retention_seconds  = 345600
  visibility_timeout_seconds = 30
  receive_wait_time_seconds  = 0
}

# Lambda Layer

data "archive_file" "lambda_layer" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_layer"
  output_path = "${path.module}/lambda_layer.zip"
}

resource "null_resource" "install_layer_dependencies" {
  triggers = {
    requirements_md5 = filemd5("${path.module}/lambda_layer/requirements.txt")
  }

  provisioner "local-exec" {
    command = "pip install -r ${path.module}/lambda_layer/requirements.txt -t ${path.module}/lambda_layer/python"
  }
}

resource "aws_lambda_layer_version" "lambda_layer" {
  filename         = data.archive_file.lambda_layer.output_path
  layer_name       = "my_lambda_layer"
  source_code_hash = data.archive_file.lambda_layer.output_base64sha256

  compatible_runtimes = ["python3.9"]

  depends_on = [null_resource.install_layer_dependencies]
}

# Lambda Function

data "archive_file" "lambda_function" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_functions/s3_file_upload_notification_processor"
  output_path = "${path.module}/lambda_functions/s3_file_upload_notification_processor.zip"
}

resource "aws_lambda_function" "lambda_function" {
  filename         = data.archive_file.lambda_function.output_path
  function_name    = "s3_file_upload_notification_processor"
  role             = aws_iam_role.lambda_role.arn
  handler          = "handler.handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.lambda_function.output_base64sha256
  layers           = [aws_lambda_layer_version.lambda_layer.arn]

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.sns_topic.arn
      SQS_QUEUE_URL = aws_sqs_queue.sqs_queue.id
    }
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda_notification_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_notification_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = "${aws_s3_bucket.upload_bucket.arn}/*"

      },
      {
        Effect   = "Allow"
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.sqs_queue.arn
      },
      {
        Effect   = "Allow"
        Action   = "sns:Publish"
        Resource = aws_sns_topic.sns_topic.arn
      }
    ]
  })
}

# S3 Bucket Notification
resource "aws_s3_bucket_notification" "s3_notification" {
  bucket = aws_s3_bucket.upload_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda_function.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

# Permission for S3 to invoke Lambda
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3InvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.upload_bucket.arn
}