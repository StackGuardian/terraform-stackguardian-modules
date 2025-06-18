data "azuread_client_config" "current" {}
data "azurerm_subscription" "current" {}

# Create Azure AD application
resource "azuread_application" "app_registration" {
  display_name = var.display_name
  owners       = [data.azuread_client_config.current.object_id]
}

# Create the Service Principal
resource "azuread_service_principal" "sg_sp" {
  client_id                    = azuread_application.app_registration.client_id
  owners                       = [data.azuread_client_config.current.object_id]
  app_role_assignment_required = false
}

# Assign Contributor role to the Service Principal at the subscription level
resource "azurerm_role_assignment" "example" {
  principal_id         = azuread_service_principal.sg_sp.object_id
  role_definition_name = "Contributor"
  scope                = data.azurerm_subscription.current.id
}

# Configure Workload Identity (Federated Credential)
resource "azuread_application_federated_identity_credential" "sg_fed_id_creds" {
  application_id = azuread_application.app_registration.id
  display_name   = "sg-federated-identity"
  audiences      = ["https://api.app.stackguardian.io"]
  issuer         = "https://api.app.stackguardian.io"
  subject        = "/orgs/${var.sg_org_name}"
}
