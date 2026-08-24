# StackGuardian Runner Autoscaler - Azure Module

> Part of [StackGuardian Private Runner](../../README.md) — [Azure stack overview](../DOCUMENTATION.md) · [platform template doc](DOCUMENTATION.md)

Deploy an Azure Function-based autoscaler that monitors StackGuardian job queues and automatically scales a VM Scale Set up or down based on workload demand.

## Overview

The autoscaler module provides intelligent scaling for StackGuardian Private Runners by monitoring job queue depth and adjusting the number of VM instances accordingly. It runs as a serverless Azure Function triggered every minute by a timer.

### What Gets Created

- **Function App**: FlexConsumption plan with Python 3.11 runtime for autoscaling logic
- **Storage Account**: Blob storage for autoscaler state (cooldown timestamps)
- **Application Insights**: Monitoring, logging, and alerting (30-day retention by default)
- **Role Assignments**: Managed identity with VMSS, storage, and network access

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Azure Subscription                       │
│                                                             │
│  ┌─────────────────────┐    ┌─────────────────────────────┐ │
│  │  Resource Group     │    │  VMSS Resource Group        │ │
│  │                     │    │  (existing)                 │ │
│  │  ┌───────────────┐  │    │  ┌───────────────────────┐  │ │
│  │  │ Function App  │──┼────┼──│ VM Scale Set          │  │ │
│  │  │ (autoscaler)  │  │    │  │ (existing runners)    │  │ │
│  │  └───────┬───────┘  │    │  └───────────────────────┘  │ │
│  │          │          │    │                             │ │
│  │  ┌───────▼───────┐  │    └─────────────────────────────┘ │
│  │  │ Storage Acct  │  │                                    │
│  │  │ (state)       │  │                                    │
│  │  └───────────────┘  │                                    │
│  │                     │                                    │
│  │  ┌───────────────┐  │                                    │
│  │  │ App Insights  │  │                                    │
│  │  │ (monitoring)  │  │                                    │
│  │  └───────────────┘  │                                    │
│  └─────────────────────┘                                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

Before deploying this module, you need:

1. **Existing VM Scale Set** - An Azure VMSS with StackGuardian runner instances
2. **StackGuardian Runner Group** - Deploy the `runner_group` module first to get:
   - `runner_group_name`
3. **StackGuardian API Key** - Organization API key (`sgu_*` or `sgo_*`) from the StackGuardian platform
4. **Azure Resource Group** - Existing resource group for autoscaler resources
5. **Azure CLI** - Authenticated (`az login`)

## Quick Start

### Step 1: Deploy Prerequisites

Ensure you have an existing VM Scale Set and StackGuardian runner group.

### Step 2: Deploy Autoscaler

```bash
terraform init
terraform apply
```

### Basic Configuration Example

```hcl
module "azure_autoscaler" {
  source = "./azure/autoscaler"

  resource_group_name = "my-resource-group"
  azure_location      = "westeurope"

  vmss = {
    name                = "my-runner-vmss"
    resource_group_name = "vmss-resource-group"
  }

  stackguardian = {
    api_key  = "sgu_xxxxxxxxxxxx"
    org_name = "my-org"
  }

  override_names = {
    global_prefix     = "sg-runner"
    runner_group_name = "my-runner-group"
  }
}
```

## Configuration

### Required Parameters

| Parameter | Description | Type |
|-----------|-------------|------|
| `resource_group_name` | Existing Azure Resource Group for autoscaler resources | `string` |
| `stackguardian.api_key` | StackGuardian API key (`sgu_*` or `sgo_*`) | `string` |
| `vmss.name` | Name of the existing VM Scale Set to manage | `string` |
| `override_names.global_prefix` | Prefix for naming all resources | `string` |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `azure_location` | Azure region for deployment | `westeurope` |
| `stackguardian.org_name` | Organization name (extracted from environment if not provided) | `""` |
| `vmss.resource_group_name` | VMSS resource group (defaults to `resource_group_name`) | `""` |
| `override_names.runner_group_name` | Override the StackGuardian runner group name | `""` |
| `scaling.scale_out_cooldown_duration` | Minutes after scale-out before scaling again (min: 4) | `4` |
| `scaling.scale_in_cooldown_duration` | Minutes after scale-in before scaling again | `5` |
| `scaling.scale_out_threshold` | Queued jobs to trigger scale-out | `3` |
| `scaling.scale_in_threshold` | Queued jobs to trigger scale-in (min: 1) | `1` |
| `scaling.scale_out_step` | Instances to add when scaling out | `1` |
| `scaling.scale_in_step` | Instances to remove when scaling in | `1` |
| `scaling.min_runners` | Minimum number of runners to maintain | `1` |
| `storage.account_tier` | Storage account performance tier | `Standard` |
| `storage.account_replication_type` | Storage replication strategy (LRS, GRS, RAGRS, ZRS) | `LRS` |
| `storage.account_url` | Explicit storage URL (for private endpoints) | `""` |
| `storage.use_rbac` | Authenticate to storage with managed identity instead of connection strings | `false` |
| `application_insights_retention_in_days` | Application Insights telemetry retention (30, 60, 90, 120, 180, 270, 365, 550, 730) | `30` |
| `autoscaler_repo.url` | Git repository URL for the Function App source | `https://github.com/StackGuardian/sg-runner-autoscaler` |
| `autoscaler_repo.branch` | Git branch for the Function App source | `main` |

### Configuration Examples

#### Basic Configuration

```hcl
module "azure_autoscaler" {
  source = "./azure/autoscaler"

  resource_group_name = "my-resource-group"

  vmss = {
    name = "my-runner-vmss"
  }

  stackguardian = {
    api_key = "sgu_xxxxxxxxxxxx"
  }

  override_names = {
    global_prefix     = "sg-runner"
    runner_group_name = "my-runner-group"
  }
}
```

#### Advanced Configuration

```hcl
module "azure_autoscaler" {
  source = "./azure/autoscaler"

  resource_group_name = "my-resource-group"
  azure_location      = "westeurope"

  vmss = {
    name                = "my-runner-vmss"
    resource_group_name = "vmss-resource-group"
  }

  stackguardian = {
    api_key  = "sgu_xxxxxxxxxxxx"
    org_name = "my-org"
  }

  override_names = {
    global_prefix     = "prod-runner"
    runner_group_name = "prod-runner-group"
  }

  scaling = {
    scale_out_cooldown_duration = 5
    scale_in_cooldown_duration  = 10
    scale_out_threshold         = 5
    scale_in_threshold          = 2
    scale_out_step              = 2
    scale_in_step               = 1
    min_runners                 = 2
  }

  storage = {
    account_tier             = "Standard"
    account_replication_type = "GRS"
  }

  application_insights_retention_in_days = 90

  autoscaler_repo = {
    url    = "https://github.com/StackGuardian/sg-runner-autoscaler"
    branch = "main"
  }
}
```

#### Private Network with Storage Endpoint

```hcl
module "azure_autoscaler" {
  source = "./azure/autoscaler"

  resource_group_name = "my-resource-group"
  azure_location      = "westeurope"

  vmss = {
    name                = "my-runner-vmss"
    resource_group_name = "vmss-resource-group"
  }

  stackguardian = {
    api_key  = "sgu_xxxxxxxxxxxx"
    org_name = "my-org"
  }

  override_names = {
    global_prefix     = "sg-runner"
    runner_group_name = "my-runner-group"
  }

  storage = {
    account_url = "https://mystorageaccount.privatelink.blob.core.windows.net"
  }
}
```

## Usage

### Terraform Deployment

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Preview changes
terraform plan

# Apply configuration
terraform apply
```

### Auto-scaling Behavior

The autoscaler operates on a 1-minute cycle:

1. **Scale-out**: When queued jobs >= `scale_out_threshold`, adds `scale_out_step` instances
2. **Scale-in**: When queued jobs <= `scale_in_threshold`, marks runners as DRAINING, then removes idle ones
3. **Cooldown**: After scaling, waits the configured cooldown duration before scaling again

Default behavior:
- Scales out when 3+ jobs are queued
- Scales in when 1 or fewer jobs are queued
- 4-minute cooldown after scale-out
- 5-minute cooldown after scale-in

### Function Code Deployment

The module clones `autoscaler_repo.url` at `autoscaler_repo.branch` and publishes
it to the Function App via `scripts/deploy_function.sh`. The deployment re-runs
whenever any of the following change:

- The repository URL or branch
- The commit currently at the tip of that branch (resolved with `git ls-remote`)
- The contents of `scripts/deploy_function.sh`
- The Function App itself (if it is recreated)

Because the branch tip is resolved on every plan, pushing a new commit to the
tracked branch is enough to make the next `tofu apply` redeploy the function code.
The local machine running the apply needs `git`, `zip`, and an authenticated
`az` CLI.

### Cleanup

```bash
# Destroy the autoscaler
terraform destroy
```

---

## Manual Deployment (Azure CLI)

For deployments without Terraform, follow this step-by-step guide using Azure CLI.

### Step 1: Set Variables

```bash
# Required - customize these
RESOURCE_GROUP="my-autoscaler-rg"
LOCATION="westeurope"
STORAGE_ACCOUNT="sgautoscaler$(openssl rand -hex 4)"
FUNCTION_APP="sg-autoscaler"
APP_INSIGHTS="sg-autoscaler-insights"

# VMSS configuration
VMSS_NAME="my-runner-vmss"
VMSS_RESOURCE_GROUP="my-vmss-rg"

# StackGuardian configuration
SG_API_KEY="sgu_xxxxxxxxxxxx"
SG_ORG="my-org"
SG_RUNNER_GROUP="my-runner-group"
SG_BASE_URI="https://api.app.stackguardian.io"

# Get subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
```

### Step 2: Create Resource Group

```bash
az group create --name $RESOURCE_GROUP --location $LOCATION
```

### Step 3: Create Storage Account

```bash
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS \
  --min-tls-version TLS1_2

# Get connection string
STORAGE_CONN_STRING=$(az storage account show-connection-string \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --query connectionString -o tsv)

# Create container for autoscaler state
az storage container create \
  --name autoscaler-state \
  --account-name $STORAGE_ACCOUNT
```

### Step 4: Create Application Insights

```bash
az monitor app-insights component create \
  --app $APP_INSIGHTS \
  --location $LOCATION \
  --resource-group $RESOURCE_GROUP \
  --application-type other

# Get connection string
APP_INSIGHTS_CONN=$(az monitor app-insights component show \
  --app $APP_INSIGHTS \
  --resource-group $RESOURCE_GROUP \
  --query connectionString -o tsv)
```

### Step 5: Create Function App

```bash
# Create Function App with FlexConsumption plan
az functionapp create \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP \
  --storage-account $STORAGE_ACCOUNT \
  --flexconsumption-location $LOCATION \
  --runtime python \
  --runtime-version 3.11 \
  --functions-version 4
```

### Step 6: Configure App Settings

The autoscaler uses **RBAC (managed identity)** to access blob storage instead of connection strings.

```bash
az functionapp config appsettings set \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP \
  --settings \
    AZURE_SUBSCRIPTION_ID="$SUBSCRIPTION_ID" \
    AZURE_RESOURCE_GROUP_NAME="$VMSS_RESOURCE_GROUP" \
    AZURE_VMSS_NAME="$VMSS_NAME" \
    AZURE_STORAGE_ACCOUNT_NAME="$STORAGE_ACCOUNT" \
    AZURE_BLOB_CONTAINER_NAME="autoscaler-state" \
    SCALE_IN_TIMESTAMP_BLOB_NAME="scale_in_timestamp" \
    SCALE_OUT_TIMESTAMP_BLOB_NAME="scale_out_timestamp" \
    SG_BASE_URI="$SG_BASE_URI" \
    SG_API_KEY="$SG_API_KEY" \
    SG_ORG="$SG_ORG" \
    SG_RUNNER_GROUP="$SG_RUNNER_GROUP" \
    SG_RUNNER_TYPE="external" \
    SCALE_OUT_COOLDOWN_DURATION="4" \
    SCALE_IN_COOLDOWN_DURATION="5" \
    SCALE_OUT_THRESHOLD="3" \
    SCALE_IN_THRESHOLD="1" \
    SCALE_IN_STEP="1" \
    SCALE_OUT_STEP="1" \
    MIN_RUNNERS="1" \
    AzureWebJobsStorage="$STORAGE_CONN_STRING" \
    APPLICATIONINSIGHTS_CONNECTION_STRING="$APP_INSIGHTS_CONN"
```

> **Note**: For private endpoints, also set `AZURE_STORAGE_ACCOUNT_URL` to the private endpoint URL (e.g., `https://mystorageaccount.privatelink.blob.core.windows.net`).

### Step 7: Assign Roles to Managed Identity

```bash
# Enable system-assigned managed identity
az functionapp identity assign \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP

# Get the principal ID
PRINCIPAL_ID=$(az functionapp identity show \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP \
  --query principalId -o tsv)

# Grant Virtual Machine Contributor on VMSS
az role assignment create \
  --assignee $PRINCIPAL_ID \
  --role "Virtual Machine Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$VMSS_RESOURCE_GROUP/providers/Microsoft.Compute/virtualMachineScaleSets/$VMSS_NAME"

# Grant Reader on VMSS resource group
az role assignment create \
  --assignee $PRINCIPAL_ID \
  --role "Reader" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$VMSS_RESOURCE_GROUP"

# Grant Storage Blob Data Contributor on storage account
STORAGE_ID=$(az storage account show --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP --query id -o tsv)
az role assignment create \
  --assignee $PRINCIPAL_ID \
  --role "Storage Blob Data Contributor" \
  --scope "$STORAGE_ID"

# Grant Network Contributor on VMSS resource group (required for scaling)
# This allows the function to join VMs to subnets and NSGs during scale operations
az role assignment create \
  --assignee $PRINCIPAL_ID \
  --role "Network Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$VMSS_RESOURCE_GROUP"
```

### Step 8: Deploy Function Code

Clone the autoscaler repository and deploy using one of these methods:

```bash
# Clone the autoscaler repository
git clone --depth 1 https://github.com/StackGuardian/sg-runner-autoscaler.git
cd sg-runner-autoscaler

# Copy Azure-specific requirements
cp azure_requirements.txt requirements.txt
```

**Option A: Using Azure Functions Core Tools (func CLI)**

```bash
func azure functionapp publish $FUNCTION_APP --python
```

**Option B: Using Azure CLI (if func CLI is not installed)**

```bash
# Create deployment package
zip -r deploy.zip . -x ".git/*"

# Deploy using Azure CLI
az functionapp deployment source config-zip \
  --resource-group $RESOURCE_GROUP \
  --name $FUNCTION_APP \
  --src deploy.zip \
  --build-remote true

# Cleanup
rm deploy.zip
```

### Step 9: Verify

```bash
# Check function app status
az functionapp show --name $FUNCTION_APP --resource-group $RESOURCE_GROUP --query state

# View recent logs
az monitor app-insights query \
  --app $APP_INSIGHTS \
  --resource-group $RESOURCE_GROUP \
  --analytics-query "traces | where timestamp > ago(10m) | order by timestamp desc | take 20"
```

---

## How It Works

1. **Timer Trigger**: Azure Function runs every minute
2. **Queue Check**: Queries StackGuardian API for pending jobs in the runner group
3. **Scale Decision**:
   - If `pending_jobs >= SCALE_OUT_THRESHOLD` --> Scale OUT (add instances)
   - If `pending_jobs <= SCALE_IN_THRESHOLD` --> Scale IN (mark runners as DRAINING)
4. **Graceful Termination**: DRAINING runners with no active tasks are deregistered and removed
5. **Cooldown**: Scaling operations respect cooldown periods to prevent thrashing
6. **State**: Timestamps stored in Azure Blob Storage

## Private Network Setup

When using private endpoints for storage (VNet integration), you need to provide the explicit storage URL:

### Terraform Configuration

```hcl
storage = {
  account_url = "https://mystorageaccount.privatelink.blob.core.windows.net"
}
```

### Manual Setup

Set the `AZURE_STORAGE_ACCOUNT_URL` environment variable:

```bash
az functionapp config appsettings set \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP \
  --settings AZURE_STORAGE_ACCOUNT_URL="https://mystorageaccount.privatelink.blob.core.windows.net"
```

> **Note**: The autoscaler uses RBAC (managed identity) for blob storage access. The `Storage Blob Data Contributor` role must be assigned to the Function App's managed identity on the storage account.

## Environment Variables Reference

| Variable | Description | Default |
|----------|-------------|---------|
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID | Required |
| `AZURE_RESOURCE_GROUP_NAME` | VMSS resource group | Required |
| `AZURE_VMSS_NAME` | VM Scale Set name | Required |
| `AZURE_STORAGE_ACCOUNT_NAME` | Storage account name (for RBAC auth) | Required |
| `AZURE_STORAGE_ACCOUNT_URL` | Explicit storage URL (for private endpoints) | Optional |
| `AZURE_BLOB_CONTAINER_NAME` | Blob container name | Required |
| `SG_BASE_URI` | StackGuardian API endpoint | Required |
| `SG_API_KEY` | StackGuardian API key | Required |
| `SG_ORG` | StackGuardian organization | Required |
| `SG_RUNNER_GROUP` | Runner group name | Required |
| `SG_RUNNER_TYPE` | Runner type | `"external"` |
| `SCALE_OUT_THRESHOLD` | Jobs to trigger scale out | `3` |
| `SCALE_IN_THRESHOLD` | Jobs to trigger scale in | `1` |
| `SCALE_OUT_STEP` | Instances to add | `1` |
| `SCALE_IN_STEP` | Instances to remove | `1` |
| `SCALE_OUT_COOLDOWN_DURATION` | Minutes between scale out | `4` |
| `SCALE_IN_COOLDOWN_DURATION` | Minutes between scale in | `5` |
| `MIN_RUNNERS` | Minimum instances to keep | `1` |

## Architecture

### Resource Organization

| File | Contents |
|------|----------|
| `provider.tf` | Azure, random, external, and null provider configuration |
| `variables.tf` | Input variable definitions and validations |
| `locals.tf` | Computed values, naming conventions, VMSS resource group resolution |
| `function_autoscaler.tf` | Function App, App Service Plan, Application Insights, code deployment |
| `rbac.tf` | Role assignments for the Function App managed identity |
| `storage.tf` | Storage Account and blob containers |
| `scripts/deploy_function.sh` | Clones the autoscaler repo and publishes the zip package to the Function App |
| `outputs.tf` | Module outputs |

### Resource Naming Convention

Resources are named using the pattern: `{sanitized_prefix}-{resource-type}`

The `global_prefix` is lowercased with underscores replaced by hyphens.

Examples with default prefix `sg-runner`:
- Function App: `sg-runner-autoscaler`
- App Service Plan: `sg-runner-autoscaler-plan`
- Application Insights: `sg-runner-autoscaler-insights`
- Storage Account: `sgrunner{random-suffix}` (alphanumeric only, max 24 chars)
- Blob Container: `autoscaler-state`

## Troubleshooting

### Common Issues

1. **401 Unauthorized (StackGuardian API)**
   - **Symptoms**: Function executes but fails to communicate with StackGuardian API
   - **Cause**: Invalid or expired `SG_API_KEY`
   - **Fix**: Update the app setting with a valid API key:
   ```bash
   az functionapp config appsettings set \
     --name <function-app> \
     --resource-group <rg> \
     --settings SG_API_KEY="sgu_your_new_key"
   ```

2. **Function fails to scale VMSS**
   - Verify the `vmss.name` matches the actual VM Scale Set name
   - Check managed identity role assignments (Virtual Machine Contributor, Network Contributor)

3. **Storage access errors**
   - Verify the Function App's managed identity has `Storage Blob Data Contributor` role
   - For private endpoints, ensure `storage.account_url` is set correctly

### Debugging Commands

```bash
# Check Function App logs
az monitor app-insights query \
  --app <app-insights-name> \
  --resource-group <rg> \
  --analytics-query "traces | order by timestamp desc | take 50"

# Check exceptions in App Insights
az monitor app-insights query \
  --app <app-insights-name> \
  --resource-group <rg> \
  --analytics-query "exceptions | order by timestamp desc | take 10"

# Check Function status
az functionapp function list --name <function-app> --resource-group <rg>

# Manually trigger Function
az functionapp function invoke \
  --name <function-app> \
  --resource-group <rg> \
  --function-name timer_trigger
```

## Outputs

| Output | Description |
|--------|-------------|
| `function_app_name` | The name of the Azure Function App |
| `function_app_id` | The ID of the Azure Function App |
| `function_app_default_hostname` | The default hostname of the Function App |
| `function_app_identity_principal_id` | The Principal ID of the Function App's managed identity |
| `storage_account_name` | The name of the Storage Account |
| `storage_account_id` | The ID of the Storage Account |
| `storage_container_name` | The name of the blob container for state |
| `application_insights_name` | The name of the Application Insights instance |
| `application_insights_instrumentation_key` | The instrumentation key for Application Insights |
| `application_insights_connection_string` | The connection string for Application Insights |
| `vmss_name` | The name of the VM Scale Set being managed |
| `vmss_resource_group` | The resource group of the VM Scale Set |

## Security Considerations

- **Managed Identity**: System-assigned managed identity with RBAC -- no credentials stored in app settings for Azure resource access
- **TLS 1.2 Enforced**: Storage account requires minimum TLS 1.2
- **Least Privilege**: Role assignments scoped to specific resources (VMSS, storage account, resource group)
- **Private Endpoint Support**: Storage can be accessed via private endpoints for VNet-integrated deployments
- **API Key Protection**: StackGuardian API key is stored as a Function App setting (encrypted at rest)
- **Log Retention**: Application Insights provides centralized logging and monitoring

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| azurerm | >= 3.0 |
| random | >= 3.0 |
| external | >= 2.0 |
| null | >= 3.0 |

## Next Steps

After deployment:

1. Monitor Function App logs for scaling events via Application Insights
2. Adjust scaling thresholds based on workload patterns
3. Review Application Insights metrics for function invocations and errors

## Support

- [StackGuardian Documentation](https://docs.stackguardian.io)
- [GitHub Issues](https://github.com/StackGuardian/terraform-stackguardian-modules/issues)
