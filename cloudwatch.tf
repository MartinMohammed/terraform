# Create log group for WAF logs
resource "aws_cloudwatch_log_group" "waf" {
  name              = "/aws/wafv2/${local.base_name}"
  retention_in_days = 30
}

# Create Kinesis Firehose for WAF logging
resource "aws_kinesis_firehose_delivery_stream" "waf" {
  name        = "${local.base_name}-waf-logs"
  destination = "s3"

  s3_configuration {
    role_arn   = aws_iam_role.firehose_waf.arn
    bucket_arn = aws_s3_bucket.waf_logs.arn
  }
}

# Create S3 bucket for WAF logs
resource "aws_s3_bucket" "waf_logs" {
  bucket = "${local.base_name}-waf-logs"
}

# IAM role for Firehose
resource "aws_iam_role" "firehose_waf" {
  name = "${local.base_name}-firehose-waf"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for Firehose
resource "aws_iam_role_policy" "firehose_waf" {
  name = "${local.base_name}-firehose-waf"
  role = aws_iam_role.firehose_waf.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.waf_logs.arn,
          "${aws_s3_bucket.waf_logs.arn}/*"
        ]
      }
    ]
  })
}

