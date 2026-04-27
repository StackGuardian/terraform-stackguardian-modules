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
# Clones the autoscaler repo and deploys using func CLI
resource "null_resource" "deploy_function_code" {
  depends_on = [azurerm_function_app_flex_consumption.autoscaler]

  triggers = {
    function_app_id = azurerm_function_app_flex_consumption.autoscaler.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      TEMP_DIR=$(mktemp -d)
      git clone --depth 1 --branch SG-3410-shared-autoscaler https://github.com/StackGuardian/sg-runner-autoscaler.git "$TEMP_DIR/repo"
      cd "$TEMP_DIR/repo"
      cp azure_requirements.txt requirements.txt

      # Create deployment package
      zip -r "$TEMP_DIR/deploy.zip" . -x ".git/*"

      # Deploy using Azure CLI
      # Exit codes 1/3 = health check or SyncTrigger timeout after successful
      # upload (known issue with Flex Consumption plans). Tolerate them; fail
      # on anything else.
      set +e
      az functionapp deployment source config-zip \
        --resource-group ${var.resource_group_name} \
        --name ${nonsensitive(azurerm_function_app_flex_consumption.autoscaler.name)} \
        --src "$TEMP_DIR/deploy.zip" \
        --build-remote true \
        --timeout 300
      AZ_EXIT=$?
      set -e
      if [ "$AZ_EXIT" -ne 0 ] && [ "$AZ_EXIT" -ne 1 ] && [ "$AZ_EXIT" -ne 3 ]; then
        echo "ERROR: Deployment failed with exit code $AZ_EXIT"
        exit $AZ_EXIT
      fi

      rm -rf "$TEMP_DIR"
    EOT
  }
}

/*-------------------------------------------+
 | Role Assignments for Function Identity   |
 +-------------------------------------------*/

# Allow Function App to manage VM Scale Set
resource "azurerm_role_assignment" "vmss_contributor" {
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${local.vmss_resource_group}/providers/Microsoft.Compute/virtualMachineScaleSets/${var.vmss.name}"
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azurerm_function_app_flex_consumption.autoscaler.identity[0].principal_id
}

# Allow Function App to read VMSS instances
resource "azurerm_role_assignment" "vmss_reader" {
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${local.vmss_resource_group}"
  role_definition_name = "Reader"
  principal_id         = azurerm_function_app_flex_consumption.autoscaler.identity[0].principal_id
}

# Allow Function App to access storage
# RBAC mode requires Storage Blob Data Owner for runtime host coordination;
# connection string mode only needs Storage Blob Data Contributor for app-level blob operations
resource "azurerm_role_assignment" "storage_blob_contributor" {
  scope                = azurerm_storage_account.autoscaler.id
  role_definition_name = var.storage.use_rbac ? "Storage Blob Data Owner" : "Storage Blob Data Contributor"
  principal_id         = azurerm_function_app_flex_consumption.autoscaler.identity[0].principal_id
}

# Queue and Table roles required for Functions runtime in RBAC mode
resource "azurerm_role_assignment" "storage_queue_data_contributor" {
  count                = var.storage.use_rbac ? 1 : 0
  scope                = azurerm_storage_account.autoscaler.id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = azurerm_function_app_flex_consumption.autoscaler.identity[0].principal_id
}

resource "azurerm_role_assignment" "storage_table_data_contributor" {
  count                = var.storage.use_rbac ? 1 : 0
  scope                = azurerm_storage_account.autoscaler.id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = azurerm_function_app_flex_consumption.autoscaler.identity[0].principal_id
}

# Allow Function App to join VMs to network resources (VNet subnets, NSGs)
# Required for VMSS scaling operations
resource "azurerm_role_assignment" "network_contributor" {
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${local.vmss_resource_group}"
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_function_app_flex_consumption.autoscaler.identity[0].principal_id
}
