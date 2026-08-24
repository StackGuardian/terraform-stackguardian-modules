# StackGuardian Runner Group + connector.
#
# The platform resources live in the shared, cloud-agnostic module so that this
# template only ever requires the Azure providers — an Azure deployment never pulls
# in the AWS provider.

module "runner_group" {
  source = "../../runner_group"

  sg_org_name = local.sg_org_name
  sg_app_uri  = local.sg_app_uri

  runner_group_name = local.runner_group_name
  connector_name    = local.connector_name
  max_runners       = var.max_runners

  storage_backend = {
    type = "azure_blob_storage"
    azure = {
      storage_account_name = local.storage_account_name
      access_key           = local.storage_access_key
      tenant_id            = data.azurerm_client_config.current.tenant_id
      subscription_id      = local.subscription_id
      client_id            = azuread_application.connector.client_id
    }
  }
}
