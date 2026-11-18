mock_provider "stackguardian" {}
# Resource IDs are parsed at plan time, so the mocks need real shapes.
mock_provider "azurerm" {
  mock_resource "azurerm_storage_account" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Storage/storageAccounts/testaccount"
    }
  }

  mock_data "azurerm_client_config" {
    defaults = {
      subscription_id = "00000000-0000-0000-0000-000000000000"
      tenant_id       = "00000000-0000-0000-0000-000000000000"
      object_id       = "00000000-0000-0000-0000-000000000000"
    }
  }
}
mock_provider "azuread" {
  mock_resource "azuread_application" {
    defaults = {
      id        = "/applications/00000000-0000-0000-0000-000000000000"
      client_id = "00000000-0000-0000-0000-000000000000"
    }
  }
}

variables {
  stackguardian = {
    api_key  = "sgu_testkey"
    org_name = "contract-org"
  }
}

run "versioning_always_on" {
  command = plan

  assert {
    condition     = azurerm_storage_account.this[0].blob_properties[0].versioning_enabled == true
    error_message = "Blob versioning must always be on for an account the module creates."
  }

  assert {
    condition     = azurerm_storage_management_policy.this[0].rule[0].actions[0].version[0].delete_after_days_since_creation == 365
    error_message = "Previous versions must be deleted after 365 days by default."
  }
}

run "old_enabled_flag_cannot_turn_versioning_off" {
  command = plan

  variables {
    storage_backend_versioning = {
      enabled                   = false
      noncurrent_retention_days = 365
    }
  }

  assert {
    condition     = azurerm_storage_account.this[0].blob_properties[0].versioning_enabled == true
    error_message = "A leftover enabled = false must not turn blob versioning off."
  }
}

run "zero_retention_keeps_versions_forever" {
  command = plan

  variables {
    storage_backend_versioning = {
      noncurrent_retention_days = 0
    }
  }

  assert {
    condition     = azurerm_storage_account.this[0].blob_properties[0].versioning_enabled == true
    error_message = "Blob versioning must be enabled."
  }

  assert {
    condition     = length(azurerm_storage_management_policy.this) == 0
    error_message = "Retention 0 must not create a delete rule."
  }
}

run "rejects_premium_tier" {
  command = plan

  variables {
    azure_storage = {
      account_tier = "Premium"
    }
  }

  expect_failures = [var.azure_storage]
}

run "existing_account_is_left_alone" {
  command = plan

  variables {
    create_storage_backend                    = false
    existing_azure_storage_account_name       = "existingaccount"
    existing_azure_storage_account_access_key = "dGVzdA=="
  }

  assert {
    condition     = length(azurerm_storage_account.this) == 0 && length(azurerm_storage_management_policy.this) == 0
    error_message = "An account the module doesn't create must not get versioning or a management policy."
  }
}

run "existing_account_warns_about_ignored_cors" {
  command = plan

  variables {
    create_storage_backend                    = false
    existing_azure_storage_account_name       = "existingaccount"
    existing_azure_storage_account_access_key = "dGVzdA=="
    storage_backend_cors_extra_origins        = ["http://localhost:3000"]
  }

  expect_failures = [check.existing_account_cors_ignored]
}

run "rejects_retention_above_azure_max" {
  command = plan

  variables {
    storage_backend_versioning = {
      noncurrent_retention_days = 100000
    }
  }

  expect_failures = [var.storage_backend_versioning]
}

run "cors_adds_extra_origins_without_duplicates" {
  command = plan

  variables {
    stackguardian = {
      api_key  = "sgu_testkey"
      api_uri  = "https://testapi.qa.stackguardian.io"
      org_name = "contract-org"
    }
    storage_backend_cors_extra_origins = ["http://localhost:3000", "https://dash.qa.stackguardian.io"]
  }

  assert {
    condition     = azurerm_storage_account.this[0].blob_properties[0].cors_rule[0].allowed_origins == tolist(["https://dash.qa.stackguardian.io", "http://localhost:3000"])
    error_message = "Extra origins must be added next to the console origin, without duplicates."
  }
}

run "cors_rejects_wildcard_origin" {
  command = plan

  variables {
    storage_backend_cors_extra_origins = ["https://*.example.com"]
  }

  expect_failures = [var.storage_backend_cors_extra_origins]
}

run "cors_rejects_path_query_and_fragment" {
  command = plan

  variables {
    storage_backend_cors_extra_origins = ["http://localhost:3000/logs", "https://a.example.com?x", "https://a.example.com#f"]
  }

  expect_failures = [var.storage_backend_cors_extra_origins]
}

run "connector_created_by_default" {
  command = plan

  assert {
    condition     = length(azuread_application.connector) == 1 && length(azurerm_role_assignment.connector_blob_reader) == 1
    error_message = "By default the module must create the connector identity and its blob reader role assignment."
  }
}

run "skip_connector_creates_no_identity" {
  command = plan

  variables {
    create_connector = false
  }

  assert {
    condition = (
      length(azuread_application.connector) == 0 &&
      length(azuread_service_principal.connector) == 0 &&
      length(azuread_application_federated_identity_credential.connector) == 0 &&
      length(azurerm_role_assignment.connector_blob_reader) == 0
    )
    error_message = "create_connector = false must create no Entra ID identity and no role assignment."
  }

  assert {
    condition     = output.connector_name == null && output.azure_connector_service_principal_object_id == null
    error_message = "Without a connector, the connector outputs must be null."
  }
}

run "skip_connector_links_existing_connector" {
  command = plan

  variables {
    create_connector        = false
    existing_connector_name = "deploy-connector"
  }

  assert {
    condition     = output.connector_name == "deploy-connector" && length(azuread_application.connector) == 0
    error_message = "The runner group must link the existing connector without creating an identity."
  }
}

run "existing_connector_name_warns_when_creating" {
  command = plan

  variables {
    existing_connector_name = "deploy-connector"
  }

  expect_failures = [check.existing_connector_name_ignored]
}
