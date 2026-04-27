/*---------------------------------+
 | Runner Group Outputs             |
 +---------------------------------*/
output "runner_group_name" {
  description = "The name of the StackGuardian runner group"
  value       = stackguardian_runner_group.this.resource_name
}

output "runner_group_id" {
  description = "The ID of the StackGuardian runner group"
  value       = stackguardian_runner_group.this.resource_name
}

output "runner_group_token" {
  description = "The token for runner registration (sensitive)"
  sensitive   = true
  value       = data.stackguardian_runner_group_token.this.runner_group_token
}

output "runner_group_url" {
  description = "Direct URL to the runner group in the StackGuardian web console"
  value       = "${local.sg_app_uri}/orchestrator/orgs/${local.sg_org_name}/runnergroups/${local.final_runner_group_name}"
}

/*---------------------------------+
 | Connector Outputs (AWS & Azure) |
 +---------------------------------*/
output "connector_name" {
  description = "The name of the StackGuardian connector (AWS or Azure)"
  value       = local.is_aws ? stackguardian_connector.aws[0].resource_name : (local.is_azure ? stackguardian_connector.azure[0].resource_name : "")
}

output "connector_id" {
  description = "The ID of the StackGuardian connector (AWS or Azure)"
  value       = local.is_aws ? stackguardian_connector.aws[0].resource_name : (local.is_azure ? stackguardian_connector.azure[0].resource_name : "")
}

output "connector_external_id" {
  description = "The external ID used for cross-account S3 access (AWS only)"
  value       = local.is_aws ? "${local.sg_org_name}:${random_string.connector_external_id[0].result}" : ""
}

/*---------------------------------+
 | Storage Backend Outputs (AWS)   |
 +---------------------------------*/
output "s3_bucket_name" {
  description = "The name of the S3 bucket used for storage backend (AWS only)"
  value       = local.s3_bucket_name
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket used for storage backend (AWS only)"
  value       = local.s3_bucket_arn
}

output "storage_backend_role_arn" {
  description = "The ARN of the IAM role for storage backend access (AWS only)"
  value       = local.is_aws ? aws_iam_role.storage_backend[0].arn : ""
}

output "storage_backend_role_name" {
  description = "The name of the IAM role for storage backend access (AWS only)"
  value       = local.is_aws ? aws_iam_role.storage_backend[0].name : ""
}

/*---------------------------------+
 | Storage Backend Outputs (Azure) |
 +---------------------------------*/
output "azure_storage_account_name" {
  description = "The name of the Azure Storage Account used for storage backend (Azure only)"
  value       = local.azure_storage_account_name
}

output "azure_storage_access_key" {
  description = "The access key for the Azure Storage Account (Azure only, sensitive)"
  sensitive   = true
  value       = local.azure_storage_access_key
}

/*---------------------------------+
 | General Outputs                 |
 +---------------------------------*/
output "cloud_provider" {
  description = "The cloud provider used for the storage backend"
  value       = var.cloud_provider
}

output "azure_location" {
  description = "The Azure region (Azure only)"
  value       = local.is_azure ? var.azure_location : ""
}

/*---------------------------------+
 | StackGuardian Platform Outputs  |
 +---------------------------------*/
output "sg_org_name" {
  description = "The StackGuardian organization name"
  value       = local.sg_org_name
}

output "sg_api_uri" {
  description = "The StackGuardian API URI"
  value       = local.sg_api_uri
}

output "aws_region" {
  description = "The AWS region (AWS only)"
  value       = local.is_aws ? var.aws_region : ""
}
