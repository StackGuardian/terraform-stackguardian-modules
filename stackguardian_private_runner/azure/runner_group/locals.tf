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

  effective_prefix = var.override_names.global_prefix

  # Platform naming: {prefix}-{name}, or just {name} when no prefix is set.
  # The name half is yours to pick; left empty it is a random suffix, which is
  # all the uniqueness a runner group needs. The subscription ID used to sit
  # here and cost 36 characters - it is a tag now.
  runner_group_base = (
    var.override_names.runner_group_name != ""
    ? var.override_names.runner_group_name
    : random_string.name_suffix.result
  )

  runner_group_name = (
    local.effective_prefix != ""
    ? "${local.effective_prefix}-${local.runner_group_base}"
    : local.runner_group_base
  )

  # The connector is created 1:1 with the runner group and shares its name -
  # they live in separate API namespaces (/integrations/ vs runnergroups/).
  connector_base = (
    var.override_names.connector_name != ""
    ? var.override_names.connector_name
    : local.runner_group_base
  )

  connector_name = (
    local.effective_prefix != ""
    ? "${local.effective_prefix}-${local.connector_base}"
    : local.connector_base
  )

  # Bare values - the platform's tags are a flat list of strings with no keys.
  platform_tags = compact([
    local.subscription_id,
    local.effective_prefix,
    var.azure_location,
  ])

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
