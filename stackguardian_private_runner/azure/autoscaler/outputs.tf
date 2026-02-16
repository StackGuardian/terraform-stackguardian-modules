/*---------------------------------+
 | Azure Function Outputs          |
 +---------------------------------*/
output "function_app_name" {
  description = "The name of the Azure Function App that handles auto-scaling"
  value       = azurerm_function_app_flex_consumption.autoscaler.name
}

output "function_app_id" {
  description = "The ID of the Azure Function App"
  value       = azurerm_function_app_flex_consumption.autoscaler.id
}

output "function_app_default_hostname" {
  description = "The default hostname of the Azure Function App"
  value       = azurerm_function_app_flex_consumption.autoscaler.default_hostname
}

output "function_app_identity_principal_id" {
  description = "The Principal ID of the Function App's managed identity"
  value       = azurerm_function_app_flex_consumption.autoscaler.identity[0].principal_id
}

/*---------------------------------+
 | Storage Outputs                 |
 +---------------------------------*/
output "storage_account_name" {
  description = "The name of the Storage Account used for autoscaler state"
  value       = azurerm_storage_account.autoscaler.name
}

output "storage_account_id" {
  description = "The ID of the Storage Account"
  value       = azurerm_storage_account.autoscaler.id
}

output "storage_container_name" {
  description = "The name of the blob container for autoscaler state"
  value       = azurerm_storage_container.autoscaler_state.name
}

/*---------------------------------+
 | Monitoring Outputs              |
 +---------------------------------*/
output "application_insights_name" {
  description = "The name of the Application Insights instance"
  value       = azurerm_application_insights.autoscaler.name
}

output "application_insights_instrumentation_key" {
  description = "The instrumentation key for Application Insights"
  value       = azurerm_application_insights.autoscaler.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "The connection string for Application Insights"
  value       = azurerm_application_insights.autoscaler.connection_string
  sensitive   = true
}

/*---------------------------------+
 | VMSS Configuration Outputs      |
 +---------------------------------*/
output "vmss_name" {
  description = "The name of the VM Scale Set being managed"
  value       = var.vmss.name
}

output "vmss_resource_group" {
  description = "The resource group of the VM Scale Set"
  value       = local.vmss_resource_group
}
