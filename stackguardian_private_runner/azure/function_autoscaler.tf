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

  tags = {
    purpose = "stackguardian-private-runner"
    prefix  = var.override_names.global_prefix
  }
}

# Application Insights for monitoring
resource "azurerm_application_insights" "autoscaler" {
  name                = "${local.sanitized_prefix}-autoscaler-insights"
  resource_group_name = var.resource_group_name
  location            = var.azure_location
  application_type    = "other"

  tags = {
    purpose = "stackguardian-private-runner"
    prefix  = var.override_names.global_prefix
  }
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
  storage_authentication_type = "StorageAccountConnectionString"
  storage_access_key          = azurerm_storage_account.autoscaler.primary_access_key

  site_config {
    application_insights_connection_string = azurerm_application_insights.autoscaler.connection_string
  }

  app_settings = {
    # Azure configuration (matches azure_service.py expectations)
    AZURE_SUBSCRIPTION_ID          = data.azurerm_client_config.current.subscription_id
    AZURE_RESOURCE_GROUP_NAME      = local.vmss_resource_group
    AZURE_VMSS_NAME                = var.vmss.name
    AZURE_BLOB_STORAGE_CONN_STRING = azurerm_storage_account.autoscaler.primary_connection_string
    AZURE_BLOB_CONTAINER_NAME      = azurerm_storage_container.autoscaler_state.name
    SCALE_IN_TIMESTAMP_BLOB_NAME   = "scale_in_timestamp"
    SCALE_OUT_TIMESTAMP_BLOB_NAME  = "scale_out_timestamp"

    # StackGuardian configuration (matches stackguardian_autoscaler.py expectations)
    SG_BASE_URI     = local.sg_api_uri
    SG_API_KEY      = var.stackguardian.api_key
    SG_ORG          = local.sg_org_name
    SG_RUNNER_GROUP = var.override_names.runner_group_name
    SG_RUNNER_TYPE  = "external"

    # Scaling configuration
    SCALE_OUT_COOLDOWN_DURATION = tostring(var.scaling.scale_out_cooldown_duration)
    SCALE_IN_COOLDOWN_DURATION  = tostring(var.scaling.scale_in_cooldown_duration)
    SCALE_OUT_THRESHOLD         = tostring(var.scaling.scale_out_threshold)
    SCALE_IN_THRESHOLD          = tostring(var.scaling.scale_in_threshold)
    SCALE_IN_STEP               = tostring(var.scaling.scale_in_step)
    SCALE_OUT_STEP              = tostring(var.scaling.scale_out_step)
    MIN_RUNNERS                 = tostring(var.scaling.min_runners)

    # Function runtime settings
    AzureWebJobsStorage                   = azurerm_storage_account.autoscaler.primary_connection_string
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.autoscaler.connection_string
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    purpose = "stackguardian-private-runner"
    prefix  = var.override_names.global_prefix
  }
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
      git clone --depth 1 https://github.com/StackGuardian/sg-runner-autoscaler.git "$TEMP_DIR/repo"
      cd "$TEMP_DIR/repo"
      cp azure_requirements.txt requirements.txt

      # Create deployment package
      zip -r "$TEMP_DIR/deploy.zip" . -x ".git/*"

      # Deploy using Azure CLI
      az functionapp deployment source config-zip \
        --resource-group ${var.resource_group_name} \
        --name ${azurerm_function_app_flex_consumption.autoscaler.name} \
        --src "$TEMP_DIR/deploy.zip" \
        --build-remote true

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
resource "azurerm_role_assignment" "storage_blob_contributor" {
  scope                = azurerm_storage_account.autoscaler.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_function_app_flex_consumption.autoscaler.identity[0].principal_id
}

# Allow Function App to join VMs to network resources (VNet subnets, NSGs)
# Required for VMSS scaling operations
resource "azurerm_role_assignment" "network_contributor" {
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${local.vmss_resource_group}"
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_function_app_flex_consumption.autoscaler.identity[0].principal_id
}
