locals {
  azure_identifiers_valid = alltrue([
    for value in [var.azure_tenant_id, var.azure_subscription_id, var.azure_client_id] :
    value != null && can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", value))
  ])
}

check "connector_credentials" {
  assert {
    condition = (
      (var.connector_kind == "AWS_STATIC" && var.aws_access_key_id != null && var.aws_secret_access_key != null && var.aws_region != null && var.aws_role_arn == null && var.azure_tenant_id == null && var.gcp_config_file_content == null) ||
      (var.connector_kind == "AWS_RBAC" && var.aws_role_arn != null && var.aws_external_id != null && var.aws_access_key_id == null && var.azure_tenant_id == null && var.gcp_config_file_content == null) ||
      (var.connector_kind == "AWS_OIDC" && var.aws_role_arn != null && var.aws_access_key_id == null && var.aws_external_id == null && var.azure_tenant_id == null && var.gcp_config_file_content == null) ||
      (var.connector_kind == "AZURE_STATIC" && local.azure_identifiers_valid && var.azure_client_secret != null && var.aws_access_key_id == null && var.aws_role_arn == null && var.gcp_config_file_content == null) ||
      (var.connector_kind == "AZURE_OIDC" && local.azure_identifiers_valid && var.azure_client_secret == null && var.aws_access_key_id == null && var.aws_role_arn == null && var.gcp_config_file_content == null) ||
      (var.connector_kind == "GCP_OIDC" && var.gcp_config_file_content != null && var.aws_access_key_id == null && var.aws_role_arn == null && var.azure_tenant_id == null)
    )
    error_message = "Supply only the credential fields required by connector_kind."
  }
}

resource "stackguardian_connector" "cloud" {
  resource_name = var.connector_name
  description   = "StackGuardian ${var.connector_kind} cloud connector"
  settings = {
    kind = var.connector_kind
    config = [merge(
      var.connector_kind == "AWS_STATIC" ? {
        aws_access_key_id     = var.aws_access_key_id
        aws_secret_access_key = var.aws_secret_access_key
        aws_default_region    = var.aws_region
      } : {},
      var.connector_kind == "AWS_RBAC" ? {
        role_arn         = var.aws_role_arn
        external_id      = var.aws_external_id
        duration_seconds = 3600
      } : {},
      var.connector_kind == "AWS_OIDC" ? { role_arn = var.aws_role_arn } : {},
      contains(["AZURE_STATIC", "AZURE_OIDC"], var.connector_kind) ? {
        arm_tenant_id       = var.azure_tenant_id
        arm_subscription_id = var.azure_subscription_id
        arm_client_id       = var.azure_client_id
      } : {},
      var.connector_kind == "AZURE_STATIC" ? { arm_client_secret = var.azure_client_secret } : {},
      var.connector_kind == "GCP_OIDC" ? { gcp_config_file_content = var.gcp_config_file_content } : {}
    )]
  }
}
