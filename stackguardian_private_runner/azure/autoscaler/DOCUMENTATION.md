# StackGuardian Runner Autoscaler - Azure Template

Deploy an Azure Function-based autoscaler that monitors StackGuardian job queues and scales a VM Scale Set up or down based on workload demand.

## Overview

This template creates an intelligent autoscaling system that monitors your StackGuardian job queues and automatically adjusts the number of runner instances on an Azure VM Scale Set. When jobs are queued, more runners are added; when the queue is empty, runners are removed to reduce costs.

### What This Template Creates

- **Function App** (FlexConsumption, Python 3.11) that checks job queue status every minute and scales runners accordingly
- **Storage Account** for autoscaler state (cooldown timestamps) with TLS 1.2 enforced
- **Application Insights** for monitoring, logging, and alerting on the autoscaler function (30-day telemetry retention by default)
- **Role Assignments** granting the Function App's managed identity scoped access to manage VMSS, storage, and networking

## Prerequisites

Before using this template, you need:

1. **VM Scale Set** - An existing Azure VMSS running StackGuardian runner instances
2. **Runner Group** - Deploy the "StackGuardian Runner Group" template first
3. **StackGuardian API Key** - Available from your organization settings
4. **Azure Resource Group** - An existing resource group for autoscaler resources
5. **Azure Permissions** - Permissions to create Function Apps, Storage Accounts, Application Insights, and role assignments

## Template Parameters

### Required Parameters

| Parameter | Description | Type |
|-----------|-------------|------|
| API Key | Your organization's API key (sgo_*/sgu_*) or a secret reference (${secret::SECRET_NAME}) | String |
| Resource Group Name | The name of the existing Azure Resource Group where autoscaler resources will be deployed | String |
| VMSS Name | Name of the existing VM Scale Set running StackGuardian runner instances | String |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| API Region | Select your StackGuardian platform region | EU1 - Europe |
| Organization Name | Your organization name on the StackGuardian Platform | (extracted from environment) |
| Azure Region | The Azure region where autoscaler resources will be deployed | westeurope |
| VMSS Resource Group | Resource group containing the VM Scale Set (defaults to the autoscaler resource group if empty) | (autoscaler resource group) |
| Global Prefix | Prefix used for naming all Azure resources created by this module | SG_RUNNER |
| Include Org in Prefix | When enabled, appends organization name to the global prefix | Disabled |
| Runner Group Name | Override the default StackGuardian runner group name | (empty) |
| Minimum Runners | Minimum number of runners to maintain | 1 |
| Maximum Runners | Maximum number of runners the autoscaler can provision | 3 |
| Desired Runners | Optional initial capacity. Leave empty to let the autoscaler choose between min and max | (empty) |
| Scale Out Threshold | Number of queued jobs to trigger scale-out | 3 |
| Scale In Threshold | Number of queued jobs below which to trigger scale-in | 1 |
| Scale Out Step | Number of instances to add when scaling out | 1 |
| Scale In Step | Number of instances to remove when scaling in | 1 |
| Scale Out Cooldown (minutes) | Minutes to wait after scale-out before scaling again (minimum: 4) | 4 |
| Scale In Cooldown (minutes) | Minutes to wait after scale-in before scaling again | 5 |
| Schedule (NCRONTAB) | Timer trigger expression that drives the Function App (every minute by default) | 0 */1 * * * * |
| Storage Account Tier | Performance tier of the storage account | Standard |
| Replication Type | Replication strategy for the storage account | LRS |
| Storage Account URL | Optional explicit storage account URL (for private endpoints) | (empty) |
| Use RBAC (Managed Identity) | Use managed identity instead of connection strings for storage authentication | Disabled |
| Application Insights Retention (days) | How long Application Insights keeps autoscaler telemetry (30, 60, 90, 120, 180, 270, 365, 550, 730) | 30 |
| Repository URL | Git repository containing the autoscaler Function App source code | https://github.com/StackGuardian/sg-runner-autoscaler |
| Branch | Git branch to deploy the autoscaler Function App code from | main |

## Important Notes

**Scaling Behavior**: The autoscaler runs on a 1-minute timer. When queued jobs reach the scale-out threshold (default: 3), runners are added; when queued jobs fall to the scale-in threshold (default: 1), runners are drained and removed down to the minimum. Cooldown periods prevent rapid scaling fluctuations.

**Dependencies**: This template requires an existing VM Scale Set and the outputs of the Runner Group template. Deploy those first and provide the VMSS name and runner group name as inputs.

**Cost Optimization**: The autoscaler reduces costs by automatically scaling VMSS instances down when runners are not needed. Tune the minimum/maximum runners and thresholds to match your workload patterns.

**Private Endpoint Support**: For VNet-integrated deployments, set the Storage Account URL to your private endpoint URL (e.g., `https://mystorageaccount.privatelink.blob.core.windows.net`).

**Storage Authentication**: Enable RBAC to authenticate to blob storage using the Function App's managed identity instead of connection strings. This is the recommended option for production deployments.

**Function Code Deployment**: The template clones the configured repository and branch and publishes the code to the Function App. The tip commit of the branch is resolved on every plan, so a new commit on the tracked branch causes the next apply to redeploy the function code. Leave the repository settings at their defaults unless you are testing a fork or a feature branch.

## Outputs

| Output | Description |
|--------|-------------|
| Function App Name | The name of the Azure Function App handling autoscaling |
| Function App Hostname | The default hostname of the Function App |
| Storage Account Name | The name of the Storage Account used for autoscaler state |
| Application Insights Name | The Application Insights instance for monitoring autoscaler logs and metrics |
| VMSS Name | The name of the VM Scale Set being managed |
| VMSS Resource Group | The resource group of the VM Scale Set |

## Security Features

- System-assigned managed identity authenticates to Azure resources via RBAC - no credentials stored in app settings
- Role assignments are scoped narrowly to the specific VMSS, storage account, and resource group (least privilege)
- Storage account requires TLS 1.2 minimum
- Private endpoint support for blob storage in VNet-integrated environments
- StackGuardian API key is marked sensitive so it is redacted from plan output, and is stored as a Function App setting (encrypted at rest)
- Application Insights provides centralized logging and alerting for audit and troubleshooting
