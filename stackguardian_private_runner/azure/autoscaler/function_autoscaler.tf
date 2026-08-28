/*-------------------------------------------+
 | Azure Function App for Autoscaling       |
 +-------------------------------------------*/

# App Service Plan (FlexConsumption for serverless)
resource "azurerm_service_plan" "autoscaler" {
  name                = "${local.sanitized_prefix}-autoscaler-plan"
  resource_group_name = var.resource_group_name
  location            = var.azure_location
  os_type             = "Linux"
  sku_name            = "FC1" # FlexConsumption plan

  tags = merge(local.common_tags, {
    Name = "${local.sanitized_prefix}-autoscaler-plan"
  })
}

# Application Insights for monitoring
resource "azurerm_application_insights" "autoscaler" {
  name                = "${local.sanitized_prefix}-autoscaler-insights"
  resource_group_name = var.resource_group_name
  location            = var.azure_location
  application_type    = "other"
  retention_in_days   = var.application_insights_retention_in_days

  tags = merge(local.common_tags, {
    Name = "${local.sanitized_prefix}-autoscaler-insights"
  })
}

# Function App with Flex Consumption plan
resource "azurerm_function_app_flex_consumption" "autoscaler" {
  name                = "${local.sanitized_prefix}-autoscaler"
  resource_group_name = var.resource_group_name
  location            = var.azure_location
  service_plan_id     = azurerm_service_plan.autoscaler.id

  # Runtime configuration
  runtime_name    = "python"
  runtime_version = "3.11"

  # Storage configuration
  storage_container_type      = "blobContainer"
  storage_container_endpoint  = "${azurerm_storage_account.autoscaler.primary_blob_endpoint}deployments"
  storage_authentication_type = var.storage.use_rbac ? "SystemAssignedIdentity" : "StorageAccountConnectionString"
  storage_access_key          = var.storage.use_rbac ? null : azurerm_storage_account.autoscaler.primary_access_key

  site_config {
    application_insights_connection_string = azurerm_application_insights.autoscaler.connection_string
  }

  app_settings = local.app_settings

  identity {
    type = "SystemAssigned"
  }

  tags = merge(local.common_tags, {
    Name = "${local.sanitized_prefix}-autoscaler"
  })
}

/*-------------------------------------------+
 | Automatic Code Deployment                 |
 +-------------------------------------------*/

# Fetch latest commit hash from remote repo to trigger redeploy on changes
data "external" "repo_commit" {
  program = [
    "sh", "-c",
    "echo \"{\\\"commit\\\": \\\"$(git ls-remote ${var.autoscaler_repo.url} ${var.autoscaler_repo.branch} | cut -f1)\\\"}\""
  ]
}

# Clones the autoscaler repo and deploys the zip package via Azure CLI
resource "terraform_data" "deploy_function_code" {
  triggers_replace = [
    azurerm_function_app_flex_consumption.autoscaler.id,
    var.autoscaler_repo.url,
    var.autoscaler_repo.branch,
    data.external.repo_commit.result.commit,
    filemd5("${path.module}/scripts/deploy_function.sh")
  ]

  provisioner "local-exec" {
    command = "sh ${path.module}/scripts/deploy_function.sh"
    environment = {
      REPO_URL            = var.autoscaler_repo.url
      REPO_BRANCH         = var.autoscaler_repo.branch
      RESOURCE_GROUP_NAME = var.resource_group_name
      FUNCTION_APP_NAME   = azurerm_function_app_flex_consumption.autoscaler.name
    }
  }
}
