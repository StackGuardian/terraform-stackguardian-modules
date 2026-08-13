mock_provider "stackguardian" {}

run "rejects_static_credentials_without_acknowledgement" {
  command = plan

  variables {
    connector_name        = "test-static"
    connector_kind        = "AWS_STATIC"
    aws_access_key_id     = "AKIATESTKEY"
    aws_secret_access_key = "test-secret"
    aws_region            = "eu-central-1"
  }

  expect_failures = [stackguardian_connector.cloud]
}

run "allows_acknowledged_static_credentials" {
  command = plan

  variables {
    connector_name           = "test-static"
    connector_kind           = "AWS_STATIC"
    allow_static_credentials = true
    aws_access_key_id        = "AKIATESTKEY"
    aws_secret_access_key    = "test-secret"
    aws_region               = "eu-central-1"
  }

  assert {
    condition     = output.connector_name == "test-static" && output.connector_kind == "AWS_STATIC"
    error_message = "Acknowledged static credentials must retain the configured connector identity."
  }
}

run "allows_non_static_credentials_without_acknowledgement" {
  command = plan

  variables {
    connector_name   = "test-oidc"
    connector_kind   = "AWS_OIDC"
    aws_role_arn     = "arn:aws:iam::123456789012:role/TestRole"
  }

  assert {
    condition     = output.connector_kind == "AWS_OIDC"
    error_message = "Non-static connector kinds must not require static credential acknowledgement."
  }
}
