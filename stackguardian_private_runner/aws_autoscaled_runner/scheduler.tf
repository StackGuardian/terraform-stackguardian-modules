# EventBridge Scheduler Schedule for triggering Lambda every minute
resource "aws_scheduler_schedule" "autoscale_trigger" {
  name       = "${var.override_names.global_prefix}-autoscale-trigger"
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
