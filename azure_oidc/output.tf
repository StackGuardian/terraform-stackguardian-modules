output "azure_oidc" {
  description = "Azure OIDC configuration details"

  value = {
    client_id            = azuread_application.app_registration.client_id
    application_id       = azuread_application.app_registration.id
    service_principal_id = azuread_service_principal.sg_sp.object_id
    tenant_id            = data.azuread_client_config.current.tenant_id
    subscription_id      = data.azurerm_subscription.current.subscription_id
    issuer               = azuread_application_federated_identity_credential.sg_fed_id_creds.issuer
    subject              = azuread_application_federated_identity_credential.sg_fed_id_creds.subject
    audience             = azuread_application_federated_identity_credential.sg_fed_id_creds.audiences[0]
  }
}