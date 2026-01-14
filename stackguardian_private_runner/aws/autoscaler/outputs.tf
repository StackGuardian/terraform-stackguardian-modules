/*-----------------------+
 | Lambda Outputs        |
 +-----------------------*/
output "lambda_function_name" {
  description = "The name of the Lambda autoscaler function"
  value       = aws_lambda_function.autoscaler.function_name
}

output "lambda_function_arn" {
  description = "The ARN of the Lambda autoscaler function"
  value       = aws_lambda_function.autoscaler.arn
}

output "lambda_role_arn" {
  description = "The ARN of the Lambda execution role"
  value       = aws_iam_role.lambda.arn
}

/*-----------------------+
 | Scheduler Outputs     |
 +-----------------------*/
output "scheduler_arn" {
  description = "The ARN of the EventBridge Scheduler"
  value       = aws_scheduler_schedule.autoscaler.arn
}

output "scheduler_name" {
  description = "The name of the EventBridge Scheduler"
  value       = aws_scheduler_schedule.autoscaler.name
}

/*-----------------------+
 | CloudWatch Outputs    |
 +-----------------------*/
output "log_group_name" {
  description = "The name of the CloudWatch Log Group for the Lambda function"
  value       = aws_cloudwatch_log_group.autoscaler.name
}
