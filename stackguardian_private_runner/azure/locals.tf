data "external" "env" {
  program = [
    "sh",
    "-c",
    "echo '{\"sg_org_name\": \"'$${SG_ORG_ID##*/}'\", \"sg_api_uri\": \"'$${SG_API_URI:-https://api.app.stackguardian.io}'\"}'"
  ]
}

data "azurerm_client_config" "current" {}

locals {
  sg_org_name = (
    var.stackguardian.org_name != ""
    ? var.stackguardian.org_name
    : data.external.env.result.sg_org_name
  )
  sg_api_uri = data.external.env.result.sg_api_uri

  # Resource group for VMSS (defaults to main resource group if not specified)
  vmss_resource_group = (
    var.vmss.resource_group_name != ""
    ? var.vmss.resource_group_name
    : var.resource_group_name
  )

  # Sanitized prefix for Azure resources (lowercase, no special chars)
  sanitized_prefix = replace(lower(var.override_names.global_prefix), "_", "-")

  # Storage account prefix (max 15 chars to leave room for 8-char random suffix + margin)
  storage_account_prefix = substr(replace(local.sanitized_prefix, "-", ""), 0, 15)
}
