/*-------------------------------------------+
 | Storage Account for Autoscaler State     |
 +-------------------------------------------*/

resource "random_string" "storage_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Storage account name must be globally unique, 3-24 chars, lowercase alphanumeric only
resource "azurerm_storage_account" "autoscaler" {
  name                     = "${local.storage_account_prefix}${random_string.storage_suffix.result}"
  resource_group_name      = var.resource_group_name
  location                 = var.azure_location
  account_tier             = var.storage.account_tier
  account_replication_type = var.storage.account_replication_type

  # Security settings
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = true

  tags = {
    purpose = "stackguardian-private-runner"
    prefix  = var.override_names.global_prefix
  }
}

# Container for autoscaler state
resource "azurerm_storage_container" "autoscaler_state" {
  name                  = "autoscaler-state"
  storage_account_id    = azurerm_storage_account.autoscaler.id
  container_access_type = "private"
}

# Container for function app deployments (required for Flex Consumption)
resource "azurerm_storage_container" "deployments" {
  name                  = "deployments"
  storage_account_id    = azurerm_storage_account.autoscaler.id
  container_access_type = "private"
}
