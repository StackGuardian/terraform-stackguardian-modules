# Lambda Function for Autoscaling
resource "aws_lambda_function" "autoscale" {
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  function_name = "${var.override_names.global_prefix}-autoscale-private-runner"
  role          = aws_iam_role.autoscale_lambda.arn
  handler       = "main.handler"
  runtime       = var.lambda_runtime
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory_size
  architectures = ["x86_64"]

  tracing_config {
    mode = "PassThrough"
  }

  environment {
    variables = {
      SCALE_OUT_COOLDOWN_DURATION = tostring(var.scaling.scale_out_cooldown_duration)
      SCALE_IN_COOLDOWN_DURATION  = tostring(var.scaling.scale_in_cooldown_duration)
      SCALE_OUT_THRESHOLD         = tostring(var.scaling.scale_out_threshold)
      SCALE_IN_THRESHOLD          = tostring(var.scaling.scale_in_threshold)
      SCALE_OUT_STEP              = tostring(var.scaling.scale_out_step)
      SCALE_IN_STEP               = tostring(var.scaling.scale_in_step)
      MIN_RUNNERS                 = tostring(var.scaling.min_size)
      SG_BASE_URI                 = var.stackguardian.api_uri
      SG_API_KEY                  = var.stackguardian.api_key
      SG_ORG                      = var.stackguardian.org_name
      SG_RUNNER_GROUP             = var.runner_group_name
      AWS_ASG_NAME                = local.asg_name
      AWS_BUCKET_NAME             = var.s3_bucket_name
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.autoscale_lambda,
    aws_cloudwatch_log_group.autoscale_lambda
  ]
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "autoscale_lambda" {
  name              = "/aws/lambda/${var.override_names.global_prefix}-autoscale-private-runner"
  retention_in_days = 14
}
