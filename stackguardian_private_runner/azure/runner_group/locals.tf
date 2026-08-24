data "external" "env" {
  program = [
    "sh",
    "-c",
    "echo '{\"sg_org_name\": \"'$${SG_ORG_ID##*/}'\"}'"
  ]
}

data "azurerm_client_config" "current" {}

locals {
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

  subscription_id = data.azurerm_client_config.current.subscription_id

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
    : "${local.effective_prefix}-runner-group-${local.subscription_id}"
  )

  connector_name = (
    var.override_names.connector_name != ""
    ? var.override_names.connector_name
    : "${local.effective_prefix}-private-runner-backend-${local.subscription_id}"
  )

  # Azure storage locals — derive from effective_prefix so org name flows into resource names
  sanitized_prefix = replace(lower(local.effective_prefix), "_", "-")

  # Storage account names must be globally unique, 3-24 chars, lowercase alphanumeric only
  storage_account_prefix = substr("stgbackend${replace(local.sanitized_prefix, "-", "")}", 0, 16)

  # Desired RG name — used both for naming a newly created RG and as a fallback. When the user
  # passes an explicit azure_resource_group_name we honor it; otherwise derive from the prefix.
  desired_resource_group_name = (
    var.azure_resource_group_name != ""
    ? var.azure_resource_group_name
    : "${local.sanitized_prefix}-rg-${local.subscription_id}"
  )

  # Effective RG name used by the module. References the resource when creating to establish
  # an implicit dependency; falls back to the user-supplied existing RG name otherwise.
  resource_group_name = (
    var.create_azure_resource_group
    ? azurerm_resource_group.this[0].name
    : var.azure_resource_group_name
  )

  storage_account_name = (
    var.create_storage_backend
    ? azurerm_storage_account.this[0].name
    : var.existing_azure_storage_account_name
  )

  storage_access_key = (
    var.create_storage_backend
    ? azurerm_storage_account.this[0].primary_access_key
    : var.existing_azure_storage_account_access_key
  )
}
