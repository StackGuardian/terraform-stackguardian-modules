data "azuread_client_config" "current" {}
data "azurerm_subscription" "current" {}

# Create Azure AD application
resource "azuread_application" "app_registration" {
  display_name = var.application_display_name
  owners       = [data.azuread_client_config.current.object_id]
}

# Create the Service Principal
resource "azuread_service_principal" "sg_sp" {
  client_id                    = azuread_application.app_registration.client_id
  owners                       = [data.azuread_client_config.current.object_id]
  app_role_assignment_required = false
}

# Assign Contributor role to the Service Principal at the subscription level
resource "azurerm_role_assignment" "subscription" {
  principal_id         = azuread_service_principal.sg_sp.object_id
  role_definition_name = var.role_definition_name
  scope                = data.azurerm_subscription.current.id
}

# Step 3: Create a Client Secret for the Service Principal
resource "azuread_service_principal_password" "client_secret" {
  service_principal_id = azuread_service_principal.sg_sp.id
  end_date_relative    = var.service_principal_password_end_date_relative
}

# Step 4: Output the Client Secret Value (ID will be available in the Service Principal)
output "client_secret_value" {
  description = "Generated service principal secret. It is stored in Terraform state."
  value       = azuread_service_principal_password.client_secret.value
  sensitive   = true
}

# Step 5: Output the Client ID (Application ID)
output "client_id" {
  description = "Client ID of the created Entra application."
  value       = azuread_application.app_registration.client_id
}

output "tenant_id" {
  description = "Tenant ID for the created service principal."
  value       = var.tenant_id
}

output "subscription_id" {
  description = "Subscription ID where the role assignment was created."
  value       = var.subscription_id
}

# Step 6: Output the Client Secret ID (from the service principal password)
output "client_secret_id" {
  description = "ID of the generated service principal password."
  value       = azuread_service_principal_password.client_secret.id
}
