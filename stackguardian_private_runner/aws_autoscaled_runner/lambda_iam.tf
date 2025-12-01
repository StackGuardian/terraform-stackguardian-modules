# IAM Role for Lambda Autoscaling Function
resource "aws_iam_role" "autoscale_lambda" {
  name = "${var.override_names.global_prefix}-autoscale-lambda-role"

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
}

# IAM Policy for Lambda Autoscaling Function
resource "aws_iam_policy" "autoscale_lambda" {
  name        = "${var.override_names.global_prefix}-autoscale-lambda-policy"
  description = "Policy for autoscaling Lambda function"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3Access"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      },
      {
        Sid    = "AutoScalingAccess"
        Effect = "Allow"
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:SetInstanceProtection",
          "autoscaling:DescribeAutoScalingGroups"
        ]
        Resource = "*"
      },
      {
        Sid    = "EC2Access"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      },
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "autoscale_lambda" {
  role       = aws_iam_role.autoscale_lambda.name
  policy_arn = aws_iam_policy.autoscale_lambda.arn
}

# IAM Role for EventBridge Scheduler
resource "aws_iam_role" "scheduler_execution" {
  name = "${var.override_names.global_prefix}-scheduler-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for EventBridge Scheduler
resource "aws_iam_policy" "scheduler_execution" {
  name        = "${var.override_names.global_prefix}-scheduler-execution-policy"
  description = "Policy for EventBridge Scheduler to invoke Lambda"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = aws_lambda_function.autoscale.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "scheduler_execution" {
  role       = aws_iam_role.scheduler_execution.name
  policy_arn = aws_iam_policy.scheduler_execution.arn
}
