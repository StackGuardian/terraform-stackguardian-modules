/*---------------------------------+
 | StackGuardian Resources Outputs |
 +---------------------------------*/
output "runner_group_name" {
  description = "The name of the StackGuardian runner group created by this module"
  value       = stackguardian_runner_group.this.resource_name
}

output "connector_name" {
  description = "The name of the StackGuardian connector created by this module"
  value       = stackguardian_connector.this.resource_name
}

output "runner_group_url" {
  description = "Direct URL to the runner group in the StackGuardian web console"
  value       = "${replace(local.sg_api_uri, "api.", "")}/orchestrator/orgs/${local.sg_org_name}/runnergroups/${stackguardian_runner_group.this.resource_name}"
}

/*-----------------------+
 | AWS Resources Outputs |
 +-----------------------*/
output "lambda_function_name" {
  description = "The name of the Lambda function that handles auto-scaling"
  value       = aws_lambda_function.autoscale.function_name
}

output "storage_backend_name" {
  description = "The name of the S3 bucket used for Terraform state storage"
  value       = aws_s3_bucket.this.bucket
}
