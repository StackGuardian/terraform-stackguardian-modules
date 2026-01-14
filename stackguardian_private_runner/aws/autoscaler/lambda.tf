# Lambda Function for Autoscaling
resource "aws_lambda_function" "autoscaler" {
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  function_name = local.lambda_function_name
  role          = aws_iam_role.lambda.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = var.lambda_config.runtime
  timeout       = var.lambda_config.timeout
  memory_size   = var.lambda_config.memory_size
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
      SG_BASE_URI                 = local.sg_api_uri
      SG_API_KEY                  = var.stackguardian.api_key
      SG_ORG                      = var.stackguardian.org_name
      SG_RUNNER_GROUP             = var.runner_group_name
      SG_RUNNER_TYPE              = var.runner_type
      AWS_ASG_NAME                = var.asg_name
      AWS_BUCKET_NAME             = var.s3_bucket_name
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda,
    aws_cloudwatch_log_group.autoscaler
  ]
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "autoscaler" {
  name              = local.log_group_name
  retention_in_days = 14
}
