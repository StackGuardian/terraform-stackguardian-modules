# Azure Resource Group (Azure only, created when create_azure_resource_group = true)
resource "azurerm_resource_group" "this" {
  count = local.is_azure && var.create_azure_resource_group ? 1 : 0

  name     = local.desired_azure_rg_name
  location = var.azure_location

  tags = {
    purpose = "stackguardian-private-runner"
    prefix  = var.override_names.global_prefix
  }

  lifecycle {
    precondition {
      condition     = local.desired_azure_rg_name != ""
      error_message = "Could not derive an Azure Resource Group name. Set var.azure_resource_group_name or var.override_names.global_prefix."
    }
  }
}

# Azure Blob Storage for Storage Backend (Azure only, created when create_storage_backend = true)

resource "random_string" "azure_storage_suffix" {
  count = local.is_azure && var.create_storage_backend ? 1 : 0

  length  = 8
  special = false
  upper   = false
}

# Storage account name must be globally unique, 3-24 chars, lowercase alphanumeric only
resource "azurerm_storage_account" "this" {
  count = local.is_azure && var.create_storage_backend ? 1 : 0

  name                     = "${local.storage_account_prefix}${random_string.azure_storage_suffix[0].result}"
  resource_group_name      = local.azure_resource_group_name
  location                 = var.azure_location
  account_tier             = var.azure_storage.account_tier
  account_replication_type = var.azure_storage.account_replication_type

  # Security settings
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = true

  lifecycle {
    precondition {
      condition     = local.azure_resource_group_name != ""
      error_message = "azure_resource_group_name resolved to empty. When create_azure_resource_group = false, you must pass an existing resource group via var.azure_resource_group_name."
    }
  }

  blob_properties {
    cors_rule {
      allowed_headers    = ["*"]
      allowed_methods    = ["GET", "HEAD", "PUT", "POST", "DELETE", "MERGE", "OPTIONS", "PATCH"]
      allowed_origins    = [replace(local.sg_api_uri, "api.", "")]
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
  count = local.is_azure && var.create_storage_backend ? 1 : 0

  name                  = "runner"
  storage_account_id    = azurerm_storage_account.this[0].id
  container_access_type = "private"
}

# Azure AD App Registration + Service Principal for OIDC connector

resource "azuread_application" "connector" {
  count        = local.is_azure ? 1 : 0
  display_name = "${local.effective_prefix}-sg-connector"

  owners = [data.azurerm_client_config.current[0].object_id]
}

resource "azuread_service_principal" "connector" {
  count     = local.is_azure ? 1 : 0
  client_id = azuread_application.connector[0].client_id

  owners = [data.azurerm_client_config.current[0].object_id]
}

resource "azuread_application_federated_identity_credential" "connector" {
  count          = local.is_azure ? 1 : 0
  application_id = azuread_application.connector[0].id
  display_name   = "${local.effective_prefix}-sg-oidc"
  issuer         = local.sg_api_uri
  subject        = "/orgs/${local.sg_org_name}"
  audiences      = [local.sg_api_uri]
}

# Grant the SP "Storage Blob Data Reader" on the storage account
resource "azurerm_role_assignment" "connector_blob_reader" {
  count                = local.is_azure && var.create_storage_backend ? 1 : 0
  scope                = azurerm_storage_account.this[0].id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azuread_service_principal.connector[0].object_id
}
