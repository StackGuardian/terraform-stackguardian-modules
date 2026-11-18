# Plan-time warnings. A failing check never blocks a plan or apply; it prints a
# warning.

check "existing_connector_name_ignored" {
  assert {
    condition     = !var.create_connector || var.existing_connector_name == ""
    error_message = "create_connector = true: existing_connector_name (${var.existing_connector_name}) is ignored and a new connector is created. Set create_connector = false to link the existing one."
  }
}

check "existing_account_cors_ignored" {
  assert {
    condition     = var.create_storage_backend || length(var.storage_backend_cors_extra_origins) == 0
    error_message = "create_storage_backend = false: storage_backend_cors_extra_origins is not applied to the existing account ${var.existing_azure_storage_account_name}. Configure CORS on it yourself."
  }
}
