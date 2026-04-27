/*-------------------------------------------+
 | Role Assignments for Function App MI      |
 +-------------------------------------------*/
# Mirrors aws/autoscaler/iam.tf in shape: all permissions granted to the
# autoscaler runtime live here. The Function App runs with a system-assigned
# managed identity; these role_assignments grant it the access it needs to
# read/scale the VMSS and read/write its own state blobs.

# Manage VM Scale Set instances (scale in/out, instance lifecycle)
resource "azurerm_role_assignment" "vmss_contributor" {
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${local.vmss_resource_group}/providers/Microsoft.Compute/virtualMachineScaleSets/${var.vmss.name}"
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azurerm_function_app_flex_consumption.autoscaler.identity[0].principal_id
}

# Read VMSS instance metadata (status, count) within the resource group
resource "azurerm_role_assignment" "vmss_reader" {
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${local.vmss_resource_group}"
  role_definition_name = "Reader"
  principal_id         = azurerm_function_app_flex_consumption.autoscaler.identity[0].principal_id
}

# Storage access for autoscaler state blobs.
# RBAC mode: Storage Blob Data Owner (runtime host coordination).
# Connection-string mode: Storage Blob Data Contributor (app-level blobs only).
resource "azurerm_role_assignment" "storage_blob_contributor" {
  scope                = azurerm_storage_account.autoscaler.id
  role_definition_name = var.storage.use_rbac ? "Storage Blob Data Owner" : "Storage Blob Data Contributor"
  principal_id         = azurerm_function_app_flex_consumption.autoscaler.identity[0].principal_id
}

# Queue + Table data contributor required by the Functions runtime in RBAC mode
resource "azurerm_role_assignment" "storage_queue_data_contributor" {
  count                = var.storage.use_rbac ? 1 : 0
  scope                = azurerm_storage_account.autoscaler.id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = azurerm_function_app_flex_consumption.autoscaler.identity[0].principal_id
}

resource "azurerm_role_assignment" "storage_table_data_contributor" {
  count                = var.storage.use_rbac ? 1 : 0
  scope                = azurerm_storage_account.autoscaler.id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = azurerm_function_app_flex_consumption.autoscaler.identity[0].principal_id
}

# Network Contributor on the VMSS resource group is required for VMSS scaling
# operations that touch VNets, subnets, NSGs.
resource "azurerm_role_assignment" "network_contributor" {
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${local.vmss_resource_group}"
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_function_app_flex_consumption.autoscaler.identity[0].principal_id
}
