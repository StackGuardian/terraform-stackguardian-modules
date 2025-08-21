/*---------------------------------+
 | StackGuardian Resources Outputs |
 +---------------------------------*/
output "runner_group_name" {
  value = stackguardian_runner_group.this.resource_name
}

output "connector_name" {
  value = stackguardian_connector.this.resource_name
}

/*-----------------------+
 | AWS Resources Outputs |
 +-----------------------*/
output "lambda_function_name" {
  value = aws_lambda_function.autoscale.function_name
}

output "storage_backend_name" {
  value = aws_s3_bucket.this.bucket
}
