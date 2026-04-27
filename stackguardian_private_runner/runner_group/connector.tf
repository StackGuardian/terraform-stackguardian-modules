# StackGuardian Connector (AWS and Azure storage backend authentication)

# AWS Connector — Uses RBAC role for S3 access
resource "stackguardian_connector" "aws" {
  count = local.is_aws ? 1 : 0

  resource_name = local.connector_name
  description   = "AWS connector for accessing Private Runner storage backend (S3 Bucket: ${local.s3_bucket_name})."

  settings = {
    kind = "AWS_RBAC"

    config = [{
      role_arn         = aws_iam_role.storage_backend[0].arn
      external_id      = "${local.sg_org_name}:${random_string.connector_external_id[0].result}"
      duration_seconds = "3600"
    }]
  }

  tags = local.default_tags
}

# Azure Connector — Uses OIDC with auto-provisioned Service Principal
resource "stackguardian_connector" "azure" {
  count = local.is_azure ? 1 : 0

  resource_name = local.connector_name
  description   = "Azure OIDC connector for Private Runner storage backend"

  settings = {
    kind = "AZURE_OIDC"

    config = [{
      arm_tenant_id       = data.azurerm_client_config.current[0].tenant_id
      arm_subscription_id = data.azurerm_client_config.current[0].subscription_id
      arm_client_id       = azuread_application.connector[0].client_id
    }]
  }

  tags = local.default_tags
}

# State migration: moved block for backward compatibility
moved {
  from = stackguardian_connector.this
  to   = stackguardian_connector.aws[0]
}
