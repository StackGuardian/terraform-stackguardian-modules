output "azure_service_principal" {
  description = "Azure Service Principal details"

  value = {
    client_id            = azuread_application.app_registration.client_id
    application_id       = azuread_application.app_registration.id
    service_principal_id = azuread_service_principal.sg_sp.object_id
    tenant_id            = data.azuread_client_config.current.tenant_id
  }
}

# output "client_secret" {
#   description = "Client secret for the Azure Service Principal"
#   value       = azuread_service_principal_password.client_secret.value
#   sensitive   = true
# }
output "client_secret" {
  description = "Client secret for the Azure App Registration"
  value       = azuread_application_password.client_secret.value
  sensitive = true
}