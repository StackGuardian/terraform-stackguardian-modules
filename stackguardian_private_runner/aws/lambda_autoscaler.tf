# IAM Role for Lambda Autoscaling Function
resource "aws_iam_role" "autoscale_lambda" {
  name = "${var.name_prefix}-autoscale-lambda-role"

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
  name        = "${var.name_prefix}-autoscale-lambda-policy"
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
          "${aws_s3_bucket.this.arn}/*"
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

# Lambda Function for Autoscaling
resource "aws_lambda_function" "autoscale" {
  package_type = "Image"
  image_uri    = "${var.image.repository}:${var.image.tag}"

  architectures = ["arm64"]

  function_name = "${var.name_prefix}-autoscale-private-runner"
  role          = aws_iam_role.autoscale_lambda.arn
  timeout       = 60
  memory_size   = 128

  environment {
    variables = {
      SCALE_OUT_COOLDOWN_DURATION = var.scale_out_cooldown_duration
      SCALE_IN_COOLDOWN_DURATION  = var.scale_in_cooldown_duration
      SCALE_OUT_THRESHOLD         = var.scale_out_threshold
      SCALE_IN_THRESHOLD          = var.scale_in_threshold
      SG_BASE_URI                 = local.sg_api_uri
      SG_API_KEY                  = var.sg_api_key
      SCALE_IN_STEP               = var.scale_in_step
      SCALE_OUT_STEP              = var.scale_out_step
      MIN_RUNNERS                 = var.min_runners
      AWS_ASG_NAME                = aws_autoscaling_group.this.name
      SG_ORG                      = local.sg_org_name
      SG_RUNNER_GROUP             = stackguardian_runner_group.this.resource_name
      AWS_BUCKET_NAME             = aws_s3_bucket.this.bucket
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.autoscale_lambda,
    aws_cloudwatch_log_group.autoscale_lambda
  ]
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "autoscale_lambda" {
  name              = "/aws/lambda/${var.name_prefix}-autoscale-private-runner"
  retention_in_days = 14
}

# EventBridge Scheduler Schedule for triggering Lambda every minute
resource "aws_scheduler_schedule" "autoscale_trigger" {
  name       = "${var.name_prefix}-autoscale-trigger"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "rate(1 minute)"

  target {
    arn      = aws_lambda_function.autoscale.arn
    role_arn = aws_iam_role.scheduler_execution.arn
  }
}

# IAM Role for EventBridge Scheduler
resource "aws_iam_role" "scheduler_execution" {
  name = "${var.name_prefix}-scheduler-execution-role"

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
  name        = "${var.name_prefix}-scheduler-execution-policy"
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
