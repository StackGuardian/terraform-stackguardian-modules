resource "stackguardian_connector" "sg_aws_static_connector" {
  count = (var.connector_type == "AWS_STATIC") ? 1 : 0
  resource_name = var.resource_name
  description = "Onboarding example of terraform-provider-stackguardian for AWSConnectorCloud"
  settings = {
    kind = var.connector_type,
    config = [{
        aws_access_key_id = var.aws_access_key_id,
        aws_secret_access_key = var.aws_secret_access_key,
        aws_default_region = var.aws_default_region
      }]
  }
  scope = ["*"]
}

resource "stackguardian_connector" "sg_azure_static_connector" {
  count = (var.connector_type == "AZURE_STATIC") ? 1 : 0
  resource_name = var.resource_name
  description = "Onboarding example of terraform-provider-stackguardian for AzureConnectorCloud"
  settings = {
    kind = var.connector_type,
    config = [{
        armTenantId = var.armTenantId,
        armSubscriptionId = var.armSubscriptionId,
        armClientId = var.armClientId,
        armClientSecret = var.armClientSecret
    }]
  }
  scope = ["*"]
}
