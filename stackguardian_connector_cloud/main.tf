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
