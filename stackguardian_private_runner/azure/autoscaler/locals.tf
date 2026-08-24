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
  sg_api_uri = var.stackguardian.api_uri

  # Resource group for VMSS (defaults to main resource group if not specified)
  vmss_resource_group = (
    var.vmss.resource_group_name != ""
    ? var.vmss.resource_group_name
    : var.resource_group_name
  )

  # Computed prefix with optional org name (matches AWS pattern)
  effective_prefix = (
    var.override_names.include_org_in_prefix && local.sg_org_name != ""
    ? "${var.override_names.global_prefix}_${local.sg_org_name}"
    : var.override_names.global_prefix
  )

  # Sanitized prefix for Azure resources (lowercase, hyphens)
  sanitized_prefix = replace(lower(local.effective_prefix), "_", "-")

  # Common tags for all taggable resources
  common_tags = {
    purpose = "stackguardian-private-runner"
    prefix  = var.override_names.global_prefix
  }

  # Storage account prefix (max 15 chars to leave room for 8-char random suffix + margin)
  storage_account_prefix = substr("autoscaler${replace(local.sanitized_prefix, "-", "")}", 0, 16)

  # Storage URL: use explicit URL if provided (for private endpoints)
  storage_account_url = (
    var.storage.account_url != ""
    ? var.storage.account_url
    : ""
  )

  # Base app settings (always present regardless of auth mode)
  base_app_settings = {
    # Azure configuration
    AZURE_SUBSCRIPTION_ID         = data.azurerm_client_config.current.subscription_id
    AZURE_RESOURCE_GROUP_NAME     = local.vmss_resource_group
    AZURE_VMSS_NAME               = var.vmss.name
    AZURE_STORAGE_ACCOUNT_NAME    = azurerm_storage_account.autoscaler.name
    AZURE_STORAGE_ACCOUNT_URL     = local.storage_account_url
    AZURE_BLOB_CONTAINER_NAME     = azurerm_storage_container.autoscaler_state.name
    SCALE_IN_TIMESTAMP_BLOB_NAME  = "scale_in_timestamp"
    SCALE_OUT_TIMESTAMP_BLOB_NAME = "scale_out_timestamp"

    # StackGuardian configuration
    SG_BASE_URI     = local.sg_api_uri
    SG_API_KEY      = var.stackguardian.api_key
    SG_ORG          = local.sg_org_name
    SG_RUNNER_GROUP = var.override_names.runner_group_name
    SG_RUNNER_TYPE  = "external"

    # Scaling configuration
    SCALE_OUT_COOLDOWN_DURATION = tostring(var.scaling.scale_out_cooldown_duration)
    SCALE_IN_COOLDOWN_DURATION  = tostring(var.scaling.scale_in_cooldown_duration)
    SCALE_OUT_THRESHOLD         = tostring(var.scaling.scale_out_threshold)
    SCALE_IN_THRESHOLD          = tostring(var.scaling.scale_in_threshold)
    SCALE_IN_STEP               = tostring(var.scaling.scale_in_step)
    SCALE_OUT_STEP              = tostring(var.scaling.scale_out_step)
    MIN_RUNNERS                 = tostring(var.scaling.min_runners)
    MAX_RUNNERS                 = tostring(var.scaling.max_runners)
    DESIRED_RUNNERS             = var.scaling.desired_runners == null ? "" : tostring(var.scaling.desired_runners)
    SCHEDULE_CRON               = var.scaling.schedule_cron

    # Monitoring
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.autoscaler.connection_string
  }

  # Storage auth app settings depend on RBAC mode
  storage_app_settings = var.storage.use_rbac ? {
    AzureWebJobsStorage__accountName = azurerm_storage_account.autoscaler.name
    } : {
    AzureWebJobsStorage = azurerm_storage_account.autoscaler.primary_connection_string
  }

  app_settings = merge(local.base_app_settings, local.storage_app_settings)
}
