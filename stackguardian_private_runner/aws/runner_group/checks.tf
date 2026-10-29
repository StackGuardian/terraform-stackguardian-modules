# Plan-time warnings. A failing check never blocks a plan or apply; it prints a
# warning, so these flag risky but allowed setups.

check "versioning_enabled" {
  assert {
    condition     = !var.create_storage_backend || var.storage_backend_versioning.enabled
    error_message = "State file versioning is OFF for the storage backend bucket: an overwritten or deleted state file cannot be recovered. Set storage_backend_versioning.enabled = true unless you have another backup of the bucket."
  }
}

check "existing_bucket_settings_ignored" {
  assert {
    condition = (
      var.create_storage_backend
      || (!var.storage_backend_versioning.enabled && length(var.storage_backend_cors_extra_origins) == 0)
    )
    error_message = "create_storage_backend = false: storage_backend_versioning and storage_backend_cors_extra_origins are not applied to the existing bucket ${var.existing_s3_bucket_name}. Configure versioning (for state file history) and CORS on it yourself."
  }
}
