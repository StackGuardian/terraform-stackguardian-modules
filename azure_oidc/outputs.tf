output "client_id" {
  description = "Client ID of the created Entra application."
  value       = azuread_application.app_registration.client_id
}

output "tenant_id" {
  description = "Tenant ID of the created Entra application."
  value       = var.tenant_id
}

output "subscription_id" {
  description = "Subscription scope of the role assignment."
  value       = var.subscription_id
}

output "federated_credential_id" {
  description = "ID of the StackGuardian federated identity credential."
  value       = azuread_application_federated_identity_credential.sg_fed_id_creds.id
}
