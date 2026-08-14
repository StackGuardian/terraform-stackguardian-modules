data "azuread_client_config" "current" {}

resource "azuread_application" "app_registration" {
  display_name = var.application_display_name
  owners       = [data.azuread_client_config.current.object_id]

  lifecycle {
    precondition {
      condition     = var.allow_static_credentials
      error_message = "Static Azure credentials are deprecated. Set allow_static_credentials = true only when required; prefer azure_oidc."
    }
  }
}

resource "azuread_service_principal" "sg_sp" {
  client_id                    = azuread_application.app_registration.client_id
  owners                       = [data.azuread_client_config.current.object_id]
  app_role_assignment_required = false

  lifecycle {
    precondition {
      condition     = var.allow_static_credentials
      error_message = "Static Azure credentials are deprecated. Set allow_static_credentials = true only when required; prefer azure_oidc."
    }
  }
}

resource "azurerm_role_assignment" "subscription" {
  principal_id         = azuread_service_principal.sg_sp.object_id
  role_definition_name = var.role_definition_name
  scope                = "/subscriptions/${var.subscription_id}"

  lifecycle {
    precondition {
      condition     = var.allow_static_credentials
      error_message = "Static Azure credentials are deprecated. Set allow_static_credentials = true only when required; prefer azure_oidc."
    }
  }
}

resource "azuread_service_principal_password" "client_secret" {
  service_principal_id = azuread_service_principal.sg_sp.id
  end_date_relative    = var.service_principal_password_end_date_relative

  lifecycle {
    precondition {
      condition     = var.allow_static_credentials
      error_message = "Static Azure credentials are deprecated. Set allow_static_credentials = true only when required; prefer azure_oidc."
    }
  }
}

resource "terraform_data" "static_credentials_deprecation" {
  count = var.allow_static_credentials ? 1 : 0
  input = "Static Azure credentials are deprecated; migrate to azure_oidc."

  provisioner "local-exec" {
    command = "printf '%s\\n' 'WARNING: Static Azure credentials are deprecated; migrate to azure_oidc.'"
  }
}
