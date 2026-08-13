data "azuread_client_config" "current" {}
data "azurerm_subscription" "current" {}

resource "azuread_application" "app_registration" {
  display_name = var.application_display_name
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "sg_sp" {
  client_id                    = azuread_application.app_registration.client_id
  owners                       = [data.azuread_client_config.current.object_id]
  app_role_assignment_required = false
}

resource "azurerm_role_assignment" "subscription" {
  principal_id         = azuread_service_principal.sg_sp.object_id
  role_definition_name = var.role_definition_name
  scope                = data.azurerm_subscription.current.id
}

resource "azuread_application_federated_identity_credential" "sg_fed_id_creds" {
  application_id = azuread_application.app_registration.id
  display_name   = var.federated_credential_name
  audiences      = var.oidc_audiences
  issuer         = var.oidc_issuer
  subject        = coalesce(var.oidc_subject, "/orgs/${var.stackguardian_org_name}")
}
