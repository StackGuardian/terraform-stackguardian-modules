mock_provider "stackguardian" {}
# ARN and ID attributes are validated at plan time, so the mocks need real shapes.
mock_provider "aws" {
  mock_resource "aws_iam_policy" {
    defaults = {
      arn = "arn:aws:iam::123456789012:policy/test-runner-s3-policy"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/test-private-runner-s3-role"
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
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
    condition     = aws_s3_bucket_versioning.this[0].versioning_configuration[0].status == "Enabled"
    error_message = "Versioning must always be on for a bucket the module creates."
  }

  assert {
    condition     = [for r in aws_s3_bucket_lifecycle_configuration.this[0].rule : r.id] == ["expire-noncurrent-versions", "abort-incomplete-multipart-uploads"]
    error_message = "By default the bucket gets the version expiry and the multipart cleanup rules."
  }

  assert {
    condition     = aws_s3_bucket_lifecycle_configuration.this[0].rule[0].noncurrent_version_expiration[0].noncurrent_days == 365
    error_message = "Noncurrent versions must expire after 365 days by default."
  }

  assert {
    condition     = aws_s3_bucket_lifecycle_configuration.this[0].rule[0].expiration[0].expired_object_delete_marker == true
    error_message = "Expired delete markers must be cleaned up."
  }

  assert {
    condition     = aws_s3_bucket_lifecycle_configuration.this[0].rule[1].abort_incomplete_multipart_upload[0].days_after_initiation == 7
    error_message = "Incomplete multipart uploads must be aborted after 7 days."
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
    condition     = aws_s3_bucket_versioning.this[0].versioning_configuration[0].status == "Enabled"
    error_message = "A leftover enabled = false must not turn versioning off."
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
    condition     = length(aws_s3_bucket_versioning.this) == 1
    error_message = "Versioning must be enabled."
  }

  assert {
    condition     = [for r in aws_s3_bucket_lifecycle_configuration.this[0].rule : r.id] == ["abort-incomplete-multipart-uploads"]
    error_message = "Retention 0 must leave only the multipart cleanup rule."
  }
}

run "existing_bucket_is_left_alone" {
  command = plan

  variables {
    create_storage_backend  = false
    existing_s3_bucket_name = "existing-bucket"
  }

  assert {
    condition     = length(aws_s3_bucket_versioning.this) == 0 && length(aws_s3_bucket_lifecycle_configuration.this) == 0
    error_message = "A bucket the module doesn't create must not get versioning or lifecycle rules."
  }
}

run "existing_bucket_warns_about_ignored_cors" {
  command = plan

  variables {
    create_storage_backend             = false
    existing_s3_bucket_name            = "existing-bucket"
    storage_backend_cors_extra_origins = ["http://localhost:3000"]
  }

  expect_failures = [check.existing_bucket_cors_ignored]
}

run "rejects_fractional_retention" {
  command = plan

  variables {
    storage_backend_versioning = {
      noncurrent_retention_days = 1.5
    }
  }

  expect_failures = [var.storage_backend_versioning]
}

run "rejects_negative_retention" {
  command = plan

  variables {
    storage_backend_versioning = {
      noncurrent_retention_days = -1
    }
  }

  expect_failures = [var.storage_backend_versioning]
}

run "cors_allows_console_origin_only_by_default" {
  command = plan

  variables {
    stackguardian = {
      api_key  = "sgu_testkey"
      api_uri  = "https://testapi.qa.stackguardian.io"
      org_name = "contract-org"
    }
  }

  assert {
    condition     = tolist(aws_s3_bucket_cors_configuration.this[0].cors_rule)[0].allowed_origins == toset(["https://dash.qa.stackguardian.io"])
    error_message = "Only the console origin of the selected API region may be allowed by default."
  }
}

run "cors_adds_extra_origins" {
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
    condition     = tolist(aws_s3_bucket_cors_configuration.this[0].cors_rule)[0].allowed_origins == toset(["https://dash.qa.stackguardian.io", "http://localhost:3000"])
    error_message = "Extra origins must be added next to the console origin, without duplicates."
  }
}

run "cors_rejects_wildcard_origin" {
  command = plan

  variables {
    storage_backend_cors_extra_origins = ["https://*"]
  }

  expect_failures = [var.storage_backend_cors_extra_origins]
}

run "cors_rejects_path_query_and_fragment" {
  command = plan

  variables {
    storage_backend_cors_extra_origins = ["http://localhost:3000/", "https://a.example.com?x", "https://a.example.com#f"]
  }

  expect_failures = [var.storage_backend_cors_extra_origins]
}
