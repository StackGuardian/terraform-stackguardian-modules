# Azure Resource Group (created when create_azure_resource_group = true)
resource "azurerm_resource_group" "this" {
  count = var.create_azure_resource_group ? 1 : 0

  name     = local.desired_resource_group_name
  location = var.azure_location

  tags = {
    purpose = "stackguardian-private-runner"
    prefix  = var.override_names.global_prefix
  }

  lifecycle {
    precondition {
      condition     = local.desired_resource_group_name != ""
      error_message = "Could not derive an Azure Resource Group name. Set var.azure_resource_group_name or var.override_names.global_prefix."
    }
  }
}

# Azure Blob Storage for Storage Backend (created when create_storage_backend = true)

resource "random_string" "storage_suffix" {
  count = var.create_storage_backend ? 1 : 0

  length  = 8
  special = false
  upper   = false
}

resource "azurerm_storage_account" "this" {
  count = var.create_storage_backend ? 1 : 0

  name                     = "${local.storage_account_prefix}${random_string.storage_suffix[0].result}"
  resource_group_name      = local.resource_group_name
  location                 = var.azure_location
  account_tier             = var.azure_storage.account_tier
  account_replication_type = var.azure_storage.account_replication_type

  # Security settings
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = true

  lifecycle {
    precondition {
      condition     = local.resource_group_name != ""
      error_message = "azure_resource_group_name resolved to empty. When create_azure_resource_group = false, you must pass an existing resource group via var.azure_resource_group_name."
    }
  }

  blob_properties {
    # Always on: the storage backend keeps the history of the runners' state
    # files, so this is not optional.
    versioning_enabled = true

    cors_rule {
      allowed_headers    = ["*"]
      allowed_methods    = ["GET", "HEAD", "PUT", "POST", "DELETE", "MERGE", "OPTIONS", "PATCH"]
      allowed_origins    = distinct(concat([local.sg_app_uri], var.storage_backend_cors_extra_origins))
      exposed_headers    = ["*"]
      max_age_in_seconds = 3600
    }
  }

  tags = {
    purpose = "stackguardian-private-runner"
    prefix  = var.override_names.global_prefix
  }
}

# Container for runner storage backend (named "runner" per SG docs requirement)
resource "azurerm_storage_container" "runner" {
  count = var.create_storage_backend ? 1 : 0

  name                  = "runner"
  storage_account_id    = azurerm_storage_account.this[0].id
  container_access_type = "private"
}

# Delete previous blob versions noncurrent_retention_days after they were
# written. Skipped when retention is 0 (keep forever).
resource "azurerm_storage_management_policy" "this" {
  count = (
    var.create_storage_backend
    && var.storage_backend_versioning.noncurrent_retention_days > 0
  ) ? 1 : 0

  storage_account_id = azurerm_storage_account.this[0].id

  rule {
    name    = "expire-noncurrent-versions"
    enabled = true

    filters {
      blob_types = ["blockBlob"]
    }

    actions {
      version {
        delete_after_days_since_creation = var.storage_backend_versioning.noncurrent_retention_days
      }
    }
  }
}
