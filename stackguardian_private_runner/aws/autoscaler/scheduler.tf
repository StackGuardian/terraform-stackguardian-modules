# EventBridge Scheduler Schedule for triggering the autoscaler Lambda
# (aws_scheduler_schedule does not support tags; only schedule groups do)
resource "aws_scheduler_schedule" "autoscaler" {
  name       = "${local.effective_prefix}-autoscale-trigger"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = var.scaling.schedule_expression

  target {
    arn      = aws_lambda_function.autoscaler.arn
    role_arn = aws_iam_role.scheduler.arn
  }
}
