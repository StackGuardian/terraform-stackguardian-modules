check "aws_static_vars" {
  assert {
    condition     = var.connector_type != "AWS_STATIC" || (var.aws_access_key_id != null && var.aws_secret_access_key != null && var.aws_default_region != null)
    error_message = "Variables aws_access_key_id, aws_secret_access_key, and aws_default_region must be set when connector_type is AWS_STATIC."
  }
}

resource "stackguardian_connector" "sg_aws_static_connector" {
  count         = (var.connector_type == "AWS_STATIC") ? 1 : 0
  resource_name = var.cloud_connector_name
  description   = "Onboarding example of terraform-provider-stackguardian for AWSConnectorCloud"
  settings = {
    kind = var.connector_type,
    config = [{
      aws_access_key_id     = var.aws_access_key_id,
      aws_secret_access_key = var.aws_secret_access_key,
      aws_default_region    = var.aws_default_region
    }]
  }
}

check "aws_oidc_vars" {
  assert {
    condition     = var.connector_type != "AWS_OIDC" || var.role_arn != null
    error_message = "Variable role_arn must be set when connector_type is AWS_OIDC."
  }
}

resource "stackguardian_connector" "sg_aws_oidc_connector" {
  count         = (var.connector_type == "AWS_OIDC") ? 1 : 0
  resource_name = var.cloud_connector_name
  description   = "Onboarding an AWS Role with OIDC"
  settings = {
    kind = var.connector_type,
    config = [{
      role_arn = var.role_arn
    }]
  }
}

check "aws_rbac_vars" {
  assert {
    condition     = var.connector_type != "AWS_RBAC" || (var.role_arn != null && var.role_external_id != null)
    error_message = "Variables role_arn and role_external_id must be set when connector_type is AWS_RBAC."
  }
}

resource "stackguardian_connector" "sg_aws_rbac_connector" {
  count         = (var.connector_type == "AWS_RBAC") ? 1 : 0
  resource_name = var.cloud_connector_name
  description   = "Onboarding an AWS Role with RBAC"
  settings = {
    kind = var.connector_type,
    config = [{
      role_arn         = var.role_arn
      external_id      = var.role_external_id
      duration_seconds = 3600
    }]
  }
}

check "azure_static_vars" {
  assert {
    condition     = var.connector_type != "AZURE_STATIC" || (var.armTenantId != null && var.armSubscriptionId != null && var.armClientId != null && var.armClientSecret != null)
    error_message = "Variables armTenantId, armSubscriptionId, armClientId, and armClientSecret must be set when connector_type is AZURE_STATIC."
  }
}

resource "stackguardian_connector" "sg_azure_static_connector" {
  count         = (var.connector_type == "AZURE_STATIC") ? 1 : 0
  resource_name = var.cloud_connector_name
  description   = "Onboarding example of terraform-provider-stackguardian for AzureConnectorCloud"
  settings = {
    kind = var.connector_type,
    config = [{
      armTenantId       = var.armTenantId,
      armSubscriptionId = var.armSubscriptionId,
      armClientId       = var.armClientId,
      armClientSecret   = var.armClientSecret
    }]
  }
}

check "azure_oidc_vars" {
  assert {
    condition     = var.connector_type != "AZURE_OIDC" || (var.armTenantId != null && var.armSubscriptionId != null && var.armClientId != null)
    error_message = "Variables armTenantId, armSubscriptionId, and armClientId must be set when connector_type is AZURE_OIDC."
  }
}

resource "stackguardian_connector" "sg_azure_oidc_connector" {
  count         = (var.connector_type == "AZURE_OIDC") ? 1 : 0
  resource_name = var.cloud_connector_name
  description   = "Onboarding example of terraform-provider-stackguardian for AzureConnectorCloud"
  settings = {
    kind = var.connector_type,
    config = [{
      armTenantId       = var.armTenantId,
      armSubscriptionId = var.armSubscriptionId,
      armClientId       = var.armClientId,
    }]
  }
}

check "gcp_oidc_vars" {
  assert {
    condition     = var.connector_type != "GCP_OIDC" || var.gcp_config_file_content != null
    error_message = "Variable gcp_config_file_content must be set when connector_type is GCP_OIDC."
  }
}

resource "stackguardian_connector" "sg_gcp_oidc_connector" {
  count         = (var.connector_type == "GCP_OIDC") ? 1 : 0
  resource_name = var.cloud_connector_name
  description   = "Onboarding example of terraform-provider-stackguardian for AzureConnectorCloud"
  settings = {
    kind = var.connector_type,
    config = [{
      gcp_config_file_content = var.gcp_config_file_content
    }]
  }
}
