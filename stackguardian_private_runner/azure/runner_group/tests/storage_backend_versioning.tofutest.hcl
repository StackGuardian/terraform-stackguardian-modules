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

run "versioning_off_by_default" {
  command = plan

  assert {
    condition     = azurerm_storage_account.this[0].blob_properties[0].versioning_enabled == false
    error_message = "Blob versioning must stay off unless storage_backend_versioning.enabled is set."
  }

  assert {
    condition     = length(azurerm_storage_management_policy.this) == 0
    error_message = "No management policy without versioning."
  }
}

run "versioning_with_one_year_retention" {
  command = plan

  variables {
    storage_backend_versioning = {
      enabled                   = true
      noncurrent_retention_days = 365
    }
  }

  assert {
    condition     = azurerm_storage_account.this[0].blob_properties[0].versioning_enabled == true
    error_message = "Blob versioning must be enabled on the storage account."
  }

  assert {
    condition     = azurerm_storage_management_policy.this[0].rule[0].actions[0].version[0].delete_after_days_since_creation == 365
    error_message = "Previous versions must be deleted after 365 days."
  }
}

run "zero_retention_keeps_versions_forever" {
  command = plan

  variables {
    storage_backend_versioning = {
      enabled                   = true
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

run "existing_account_is_left_alone" {
  command = plan

  variables {
    create_storage_backend                    = false
    existing_azure_storage_account_name       = "existingaccount"
    existing_azure_storage_account_access_key = "dGVzdA=="
    storage_backend_versioning = {
      enabled = true
    }
  }

  assert {
    condition     = length(azurerm_storage_account.this) == 0 && length(azurerm_storage_management_policy.this) == 0
    error_message = "An account the module doesn't create must not get versioning or a management policy."
  }
}

run "rejects_retention_above_azure_max" {
  command = plan

  variables {
    storage_backend_versioning = {
      enabled                   = true
      noncurrent_retention_days = 100000
    }
  }

  expect_failures = [var.storage_backend_versioning]
}
