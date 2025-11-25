# Azure Private Runner Autoscaler

Deploy an Azure Function-based autoscaler for managing StackGuardian Private Runners on an existing Azure VM Scale Set.

## Overview

The autoscaler monitors StackGuardian's job queue and automatically scales your VM Scale Set:
- **Scale OUT**: When pending jobs exceed threshold, add VM instances
- **Scale IN**: When pending jobs fall below threshold, gracefully drain and remove instances
- **Cooldown**: Respects configurable cooldown periods between scaling operations

## Architecture

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

- Azure CLI authenticated (`az login`)
- Azure Functions Core Tools v4+ (`func --version`) - *optional, can use Azure CLI instead*
- Git
- Existing VM Scale Set with StackGuardian runner instances
- StackGuardian API Key (starts with `sgu_`)
- StackGuardian Runner Group name

---

## Option 1: Manual Setup

Step-by-step guide to deploy the autoscaler using Azure CLI.

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

```bash
az functionapp config appsettings set \
  --name $FUNCTION_APP \
  --resource-group $RESOURCE_GROUP \
  --settings \
    AZURE_SUBSCRIPTION_ID="$SUBSCRIPTION_ID" \
    AZURE_RESOURCE_GROUP_NAME="$VMSS_RESOURCE_GROUP" \
    AZURE_VMSS_NAME="$VMSS_NAME" \
    AZURE_BLOB_STORAGE_CONN_STRING="$STORAGE_CONN_STRING" \
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

## Option 2: Terraform Module (WIP)

> **Note**: This Terraform module is a work in progress and automates the manual steps above.

### Prerequisites

- Terraform >= 1.0
- Azure CLI authenticated (`az login`)
- Git

### Usage

```hcl
module "azure_autoscaler" {
  source = "./stackguardian_private_runner/azure"

  resource_group_name = "my-existing-resource-group"
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

  scaling = {
    scale_out_cooldown_duration = 4
    scale_in_cooldown_duration  = 5
    scale_out_threshold         = 3
    scale_in_threshold          = 1
    scale_in_step               = 1
    scale_out_step              = 1
    min_runners                 = 1
  }
}
```

```bash
terraform init
terraform apply
```

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `azure_location` | Azure region | `string` | `"westeurope"` | no |
| `resource_group_name` | Resource group name | `string` | n/a | yes |
| `stackguardian` | SG platform config | `object` | n/a | yes |
| `vmss` | VM Scale Set config | `object` | n/a | yes |
| `override_names` | Naming overrides | `object` | See defaults | no |
| `scaling` | Scaling parameters | `object` | See defaults | no |
| `storage` | Storage config | `object` | See defaults | no |

### Outputs

| Name | Description |
|------|-------------|
| `function_app_name` | Name of the Azure Function App |
| `function_app_default_hostname` | Default hostname |
| `storage_account_name` | Name of the Storage Account |

---

## How It Works

1. **Timer Trigger**: Azure Function runs every minute
2. **Queue Check**: Queries StackGuardian API for pending jobs in the runner group
3. **Scale Decision**:
   - If `pending_jobs >= SCALE_OUT_THRESHOLD` → Scale OUT (add instances)
   - If `pending_jobs <= SCALE_IN_THRESHOLD` → Scale IN (mark runners as DRAINING)
4. **Graceful Termination**: DRAINING runners with no active tasks are deregistered and removed
5. **Cooldown**: Scaling operations respect cooldown periods to prevent thrashing
6. **State**: Timestamps stored in Azure Blob Storage

## Environment Variables Reference

| Variable | Description | Default |
|----------|-------------|---------|
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID | Required |
| `AZURE_RESOURCE_GROUP_NAME` | VMSS resource group | Required |
| `AZURE_VMSS_NAME` | VM Scale Set name | Required |
| `AZURE_BLOB_STORAGE_CONN_STRING` | Storage connection string | Required |
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

## Troubleshooting

### Check Function App Logs
```bash
az monitor app-insights query \
  --app <app-insights-name> \
  --resource-group <rg> \
  --analytics-query "traces | order by timestamp desc | take 50"
```

### Check Function Status
```bash
az functionapp function list --name <function-app> --resource-group <rg>
```

### Manually Trigger Function
```bash
az functionapp function invoke \
  --name <function-app> \
  --resource-group <rg> \
  --function-name timer_trigger
```
