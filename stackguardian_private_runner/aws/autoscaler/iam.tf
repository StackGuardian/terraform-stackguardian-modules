/*-----------------------+
 | Lambda IAM            |
 +-----------------------*/

# IAM Role for Lambda Autoscaling Function
resource "aws_iam_role" "lambda" {
  name = "${local.effective_prefix}-autoscale-lambda-role"

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

  tags = merge(local.common_tags, {
    Name = "${local.effective_prefix}-autoscale-lambda-role"
  })
}

# IAM Policy for Lambda Autoscaling Function
resource "aws_iam_policy" "lambda" {
  name        = "${local.effective_prefix}-autoscale-lambda-policy"
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
        # Mutating calls support resource-level permissions, so they are
        # scoped to this module's Auto Scaling Group only
        Sid    = "AutoScalingAccess"
        Effect = "Allow"
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:SetInstanceProtection"
        ]
        Resource = local.asg_arn
      },
      {
        # autoscaling:DescribeAutoScalingGroups and ec2:DescribeInstances do
        # not support resource-level permissions; AWS rejects any resource
        # other than "*" for them, so they stay unscoped by necessity
        Sid    = "DescribeAccess"
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      },
      {
        # Both the log group itself (CreateLogGroup) and its streams
        # (CreateLogStream, PutLogEvents) have to be listed
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          aws_cloudwatch_log_group.autoscaler.arn,
          "${aws_cloudwatch_log_group.autoscaler.arn}:*"
        ]
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.effective_prefix}-autoscale-lambda-policy"
  })
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}

/*-----------------------+
 | Scheduler IAM         |
 +-----------------------*/

# IAM Role for EventBridge Scheduler
resource "aws_iam_role" "scheduler" {
  name = "${local.effective_prefix}-scheduler-execution-role"

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

  tags = merge(local.common_tags, {
    Name = "${local.effective_prefix}-scheduler-execution-role"
  })
}

# IAM Policy for EventBridge Scheduler
resource "aws_iam_policy" "scheduler" {
  name        = "${local.effective_prefix}-scheduler-execution-policy"
  description = "Policy for EventBridge Scheduler to invoke Lambda"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = aws_lambda_function.autoscaler.arn
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.effective_prefix}-scheduler-execution-policy"
  })
}

resource "aws_iam_role_policy_attachment" "scheduler" {
  role       = aws_iam_role.scheduler.name
  policy_arn = aws_iam_policy.scheduler.arn
}
