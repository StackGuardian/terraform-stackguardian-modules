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

run "versioning_off_by_default" {
  command = plan

  assert {
    condition     = length(aws_s3_bucket_versioning.this) == 0
    error_message = "Versioning must stay off unless storage_backend_versioning.enabled is set."
  }

  assert {
    condition     = length(aws_s3_bucket_lifecycle_configuration.this) == 0
    error_message = "No lifecycle rule without versioning."
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
    condition     = aws_s3_bucket_versioning.this[0].versioning_configuration[0].status == "Enabled"
    error_message = "Versioning must be enabled on the bucket."
  }

  assert {
    condition     = aws_s3_bucket_lifecycle_configuration.this[0].rule[0].noncurrent_version_expiration[0].noncurrent_days == 365
    error_message = "Noncurrent versions must expire after 365 days."
  }

  assert {
    condition     = aws_s3_bucket_lifecycle_configuration.this[0].rule[0].expiration[0].expired_object_delete_marker == true
    error_message = "Expired delete markers must be cleaned up."
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
    condition     = length(aws_s3_bucket_versioning.this) == 1
    error_message = "Versioning must be enabled."
  }

  assert {
    condition     = length(aws_s3_bucket_lifecycle_configuration.this) == 0
    error_message = "Retention 0 must not create an expiry rule."
  }
}

run "existing_bucket_is_left_alone" {
  command = plan

  variables {
    create_storage_backend  = false
    existing_s3_bucket_name = "existing-bucket"
    storage_backend_versioning = {
      enabled = true
    }
  }

  assert {
    condition     = length(aws_s3_bucket_versioning.this) == 0 && length(aws_s3_bucket_lifecycle_configuration.this) == 0
    error_message = "A bucket the module doesn't create must not get versioning or lifecycle rules."
  }
}

run "rejects_fractional_retention" {
  command = plan

  variables {
    storage_backend_versioning = {
      enabled                   = true
      noncurrent_retention_days = 1.5
    }
  }

  expect_failures = [var.storage_backend_versioning]
}

run "rejects_negative_retention" {
  command = plan

  variables {
    storage_backend_versioning = {
      enabled                   = true
      noncurrent_retention_days = -1
    }
  }

  expect_failures = [var.storage_backend_versioning]
}
