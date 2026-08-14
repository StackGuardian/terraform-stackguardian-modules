output "client_secret_value" {
  description = "Generated service principal secret. It is stored in Terraform state."
  value       = azuread_service_principal_password.client_secret.value
  sensitive   = true
}

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

output "client_secret_id" {
  description = "ID of the generated service principal password."
  value       = azuread_service_principal_password.client_secret.id
}
