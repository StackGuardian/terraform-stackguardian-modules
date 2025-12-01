/*---------------------------------+
 | Runner Group Outputs             |
 +---------------------------------*/
output "runner_group_name" {
  description = "The name of the StackGuardian runner group"
  value = (
    var.mode == "create"
    ? stackguardian_runner_group.this[0].resource_name
    : data.stackguardian_runner_group.existing[0].resource_name
  )
}

output "runner_group_id" {
  description = "The ID of the StackGuardian runner group"
  value = (
    var.mode == "create"
    ? stackguardian_runner_group.this[0].resource_name
    : data.stackguardian_runner_group.existing[0].resource_name
  )
}

output "runner_group_token" {
  description = "The token for runner registration (sensitive)"
  sensitive   = true
  value = (
    var.mode == "create"
    ? data.stackguardian_runner_group_token.created[0].runner_group_token
    : data.stackguardian_runner_group_token.existing[0].runner_group_token
  )
}

output "runner_group_url" {
  description = "Direct URL to the runner group in the StackGuardian web console"
  sensitive   = true
  value       = "${replace(local.sg_api_uri, "api.", "")}/orchestrator/orgs/${local.sg_org_name}/runnergroups/${local.final_runner_group_name}"
}

/*---------------------------------+
 | Connector Outputs               |
 +---------------------------------*/
output "connector_name" {
  description = "The name of the StackGuardian connector"
  value       = var.mode == "create" ? stackguardian_connector.this[0].resource_name : ""
}

output "connector_id" {
  description = "The ID of the StackGuardian connector"
  value       = var.mode == "create" ? stackguardian_connector.this[0].resource_name : ""
}

output "connector_external_id" {
  description = "The external ID used for cross-account S3 access"
  sensitive   = true
  value       = var.mode == "create" ? "${local.sg_org_name}:${random_string.connector_external_id[0].result}" : ""
}

/*---------------------------------+
 | Storage Backend Outputs         |
 +---------------------------------*/
output "s3_bucket_name" {
  description = "The name of the S3 bucket used for storage backend"
  value       = local.s3_bucket_name
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket used for storage backend"
  value       = local.s3_bucket_arn
}

output "storage_backend_role_arn" {
  description = "The ARN of the IAM role for storage backend access"
  value       = var.mode == "create" ? aws_iam_role.storage_backend[0].arn : ""
}

output "storage_backend_role_name" {
  description = "The name of the IAM role for storage backend access"
  value       = var.mode == "create" ? aws_iam_role.storage_backend[0].name : ""
}

/*---------------------------------+
 | StackGuardian Platform Outputs  |
 +---------------------------------*/
output "sg_org_name" {
  description = "The StackGuardian organization name"
  sensitive   = true
  value       = local.sg_org_name
}

output "sg_api_uri" {
  description = "The StackGuardian API URI"
  value       = local.sg_api_uri
}

output "aws_region" {
  description = "The AWS region"
  value       = var.aws_region
}
