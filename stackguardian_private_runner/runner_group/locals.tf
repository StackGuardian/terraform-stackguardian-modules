data "external" "env" {
  program = [
    "sh",
    "-c",
    "echo '{\"sg_org_name\": \"'$${SG_ORG_ID##*/}'\"}'"
  ]
}

data "aws_caller_identity" "current" {
  count = var.cloud_provider == "aws" ? 1 : 0
}

data "azurerm_client_config" "current" {
  count = var.cloud_provider == "azure" ? 1 : 0
}

locals {
  # Cloud provider booleans
  is_aws   = var.cloud_provider == "aws"
  is_azure = var.cloud_provider == "azure"

  # Account identifier for resource naming
  account_identifier = (
    local.is_aws
    ? data.aws_caller_identity.current[0].account_id
    : data.azurerm_client_config.current[0].subscription_id
  )

  # StackGuardian configuration
  # Use nonsensitive() for non-secret fields to prevent sensitivity propagation
  sg_org_name = (
    nonsensitive(var.stackguardian.org_name) != ""
    ? nonsensitive(var.stackguardian.org_name)
    : data.external.env.result.sg_org_name
  )
  sg_api_uri = nonsensitive(var.stackguardian.api_uri)

  # Web console URL per platform region. Kept as an explicit map because the
  # console host is not derivable from the API host in every region.
  sg_app_uris = {
    "https://api.app.stackguardian.io"    = "https://app.stackguardian.io"
    "https://api.us.stackguardian.io"     = "https://us.stackguardian.io"
    "https://testapi.qa.stackguardian.io" = "https://dash.qa.stackguardian.io"
  }
  sg_app_uri = local.sg_app_uris[local.sg_api_uri]

  # Computed prefix with optional org name
  effective_prefix = (
    var.override_names.include_org_in_prefix && local.sg_org_name != ""
    ? "${var.override_names.global_prefix}_${local.sg_org_name}"
    : var.override_names.global_prefix
  )

  # Resource naming
  runner_group_name = (
    var.override_names.runner_group_name != ""
    ? var.override_names.runner_group_name
    : "${local.effective_prefix}-runner-group-${local.account_identifier}"
  )

  connector_name = (
    var.override_names.connector_name != ""
    ? var.override_names.connector_name
    : "${local.effective_prefix}-private-runner-backend-${local.account_identifier}"
  )

  # Default tags (not editable by user)
  default_tags = [
    "StackGuardian Private Runner",
    local.runner_group_name,
    local.sg_org_name
  ]

  # S3 bucket name / ARN (AWS only, empty for Azure)
  s3_bucket_name = (
    local.is_aws
    ? (var.create_storage_backend ? aws_s3_bucket.this[0].bucket : var.existing_s3_bucket_name)
    : ""
  )

  s3_bucket_arn = (
    local.is_aws
    ? (var.create_storage_backend ? aws_s3_bucket.this[0].arn : "arn:aws:s3:::${local.s3_bucket_name}")
    : ""
  )

  # Azure storage locals — derive from effective_prefix so org name flows into resource names
  sanitized_prefix       = replace(lower(local.effective_prefix), "_", "-")
  storage_account_prefix = substr("stgbackend${replace(local.sanitized_prefix, "-", "")}", 0, 16)

  azure_storage_account_name = (
    local.is_azure
    ? (
      var.create_storage_backend
      ? azurerm_storage_account.this[0].name
      : var.existing_azure_storage_account_name
    )
    : ""
  )

  azure_storage_access_key = (
    local.is_azure
    ? (
      var.create_storage_backend
      ? azurerm_storage_account.this[0].primary_access_key
      : var.existing_azure_storage_account_access_key
    )
    : ""
  )

  # Runner group outputs
  final_runner_group_name = stackguardian_runner_group.this.resource_name
  final_connector_name    = local.is_aws ? stackguardian_connector.aws[0].resource_name : (local.is_azure ? stackguardian_connector.azure[0].resource_name : "")
}
