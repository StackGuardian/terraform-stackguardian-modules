# Azure AD App Registration + Service Principal backing the OIDC connector.
# The connector itself is created by the shared runner_group module from these IDs.
# All of it is skipped when create_connector = false.

resource "azuread_application" "connector" {
  count = var.create_connector ? 1 : 0

  display_name = "${var.override_names.global_prefix}-sg-connector"

  owners = [data.azurerm_client_config.current.object_id]
}

resource "azuread_service_principal" "connector" {
  count = var.create_connector ? 1 : 0

  client_id = azuread_application.connector[0].client_id

  owners = [data.azurerm_client_config.current.object_id]
}

resource "azuread_application_federated_identity_credential" "connector" {
  count = var.create_connector ? 1 : 0

  application_id = azuread_application.connector[0].id
  display_name   = "${var.override_names.global_prefix}-sg-oidc"
  issuer         = local.sg_api_uri
  subject        = "/orgs/${local.sg_org_name}"
  audiences      = [local.sg_api_uri]
}

# Grant the SP "Storage Blob Data Reader" on the storage account
resource "azurerm_role_assignment" "connector_blob_reader" {
  count = var.create_connector && var.create_storage_backend && var.create_blob_reader_role_assignment ? 1 : 0

  scope                = azurerm_storage_account.this[0].id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azuread_service_principal.connector[0].object_id
}

# The identity resources gained a count when create_connector was introduced.
# These keep a state written before that from destroying and recreating them.
moved {
  from = azuread_application.connector
  to   = azuread_application.connector[0]
}

moved {
  from = azuread_service_principal.connector
  to   = azuread_service_principal.connector[0]
}

moved {
  from = azuread_application_federated_identity_credential.connector
  to   = azuread_application_federated_identity_credential.connector[0]
}
