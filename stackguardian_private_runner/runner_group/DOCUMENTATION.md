# StackGuardian Runner Group - AWS or Azure Template

Deploy a StackGuardian Runner Group with a cloud storage backend (AWS S3 or Azure Blob Storage) directly from the StackGuardian platform.

## Overview

This template provisions everything required to run private runners against either AWS or Azure. It creates a runner group on the StackGuardian platform, sets up a private storage backend for workflow artifacts, and configures secure access between StackGuardian and the chosen cloud account. Default tags ("StackGuardian Private Runner", the runner group name, and the organization name) are applied automatically to the StackGuardian resources.

### What This Template Creates

**Always:**
- **Runner Group** — A dedicated group on the StackGuardian platform to organize your private runners.
- **Cloud Connector** — Secure integration between StackGuardian and your cloud account (AWS RBAC role for AWS; OIDC federation with an Azure AD application for Azure).

**For AWS:**
- **S3 Storage Bucket** — Private bucket for workflow outputs and artifacts (or an existing bucket).
- **IAM Access Role** — Cross-account role with an external ID for secure platform access.

**For Azure:**
- **Azure Storage Account + private "runner" container** — Storage for workflow outputs and artifacts (or an existing storage account).
- **Azure AD application + service principal** — Identity for the OIDC connector, granted `Storage Blob Data Reader` on the storage account.

## Prerequisites

- A StackGuardian API key for your organization.
- For AWS: AWS account credentials in your StackGuardian workspace with permissions to create S3 buckets and IAM roles.
- For Azure: Azure account credentials in your StackGuardian workspace with permissions to create Storage Accounts, Azure AD applications, service principals, and role assignments — plus an **existing Azure Resource Group** to host the storage account.

## Template Parameters

### Required Parameters

| Parameter | Description | Type |
|-----------|-------------|------|
| API Key | Your organization's API key on the StackGuardian Platform (`sgu_*`/`sgo_*`) or a secret reference (`${secret::SECRET_NAME}`) | Password |

When **Cloud Provider** is set to **Azure** and **Create Storage Backend** is enabled, **Azure Resource Group Name** is also required.

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| API Region | Your StackGuardian platform region (EU1 / US1 / DASH) | EU1 - Europe |
| Organization Name | Your organization name (auto-detected from environment if omitted) | Auto-detected |
| Cloud Provider | Cloud provider for the storage backend (AWS or Azure) | AWS |
| AWS Region | The target AWS Region for S3 bucket and IAM resources | eu-central-1 |
| Azure Region | The Azure region where storage resources will be deployed | westeurope |
| Azure Resource Group Name | Name of the existing Azure Resource Group for the storage account | — |
| Create Storage Backend | Whether to create a new storage backend (S3 bucket for AWS, Storage Account for Azure) | Enabled |
| Existing S3 Bucket Name | Name of an existing S3 bucket to use (AWS, when not creating new) | — |
| Existing Azure Storage Account Name | Name of an existing Azure Storage Account to use (Azure, when not creating new) | — |
| Existing Azure Storage Account Access Key | Access key for the existing Azure Storage Account (Azure, sensitive) | — |
| Force Destroy Storage Backend | Delete all data in the S3 bucket on destroy (AWS only, use with caution) | Disabled |
| Azure Storage — Account Tier | Performance tier of the Azure Storage Account (Standard / Premium) | Standard |
| Azure Storage — Replication Type | Replication strategy of the Azure Storage Account (LRS / GRS / RAGRS / ZRS) | LRS |
| Global Prefix | Prefix used for naming all resources | SG_RUNNER |
| Include Organization Name in Prefix | Append the org name to the prefix (e.g. `SG_RUNNER_demo-org`) | Disabled |
| Runner Group Name Override | Custom name for the runner group | Auto-generated |
| Connector Name Override | Custom name for the cloud connector | Auto-generated |
| Maximum Runners | Maximum number of runners allowed in the group | 3 |

## Important Notes

**Cloud Provider**: The Cloud Provider toggle drives every other Azure / AWS option. Switching it after deployment will recreate cloud resources, so choose carefully up front.

**Azure Resource Group**: The template **does not create an Azure Resource Group**. You must point Azure Resource Group Name at an existing one when creating a new Azure storage backend.

**API Key Security**: The API key is stored securely and used only to authenticate with the StackGuardian platform. It must be `sgu_*` (user key), `sgo_*` (organization key), or a `${secret::SECRET_NAME}` reference.

**Storage Backend Options**: You can either create a new storage backend (recommended) or point to an existing one. When using an existing S3 bucket or Azure Storage Account, ensure it has the appropriate permissions and CORS configuration.

**Resource Naming**: By default, resources use the pattern `SG_RUNNER-{type}-{account_or_subscription_id}`. Customize via the naming options if you need stable, project-specific names.

**Data Retention**: **Force Destroy Storage Backend** (AWS only) deletes all bucket contents on destroy. Leave it disabled to protect your data. The Azure Storage Account is always destroyed on `terraform destroy` along with its contents — back up anything you need first.

## Outputs

| Output | Description |
|--------|-------------|
| Runner Group Name | Name of the created runner group, used in workflow configurations |
| Runner Group Token | Authentication token for registering runners (sensitive) |
| Runner Group URL | Direct link to manage the runner group in the StackGuardian console |
| Connector Name | Name of the AWS or Azure connector integration |
| S3 Bucket Name | Name of the storage bucket (AWS only) |
| Storage Backend Role ARN | IAM role ARN required by AWS runner instances (AWS only) |
| Azure Storage Account Name | Name of the Azure Storage Account (Azure only) |
| Azure Storage Access Key | Access key for the Azure Storage Account (Azure only, sensitive) |

## Security Features

- **Private storage** — S3 bucket has public access blocked; Azure Storage Account disables nested public items and enforces TLS 1.2 minimum.
- **Scoped access** — AWS IAM policy grants only the S3 actions runners need; Azure service principal is granted only `Storage Blob Data Reader` on the storage account.
- **Cross-account / federated identity** — AWS uses a cross-account role with an external ID; Azure uses OIDC federation, so no long-lived secret is stored on the platform.
- **CORS protection** — Both backends accept requests only from the StackGuardian platform origin.
- **Sensitive output protection** — Runner registration tokens and Azure storage access keys are marked sensitive in module outputs.

## Usage

After deploying this template, use the outputs to:

1. **Deploy Runners** — Pass the runner group name, token, and storage details to the matching runner template:
   - **AWS**: `runner_group_name`, `runner_group_token`, `s3_bucket_name`, `storage_backend_role_arn` → AWS Autoscaled Runner / AWS Runner.
   - **Azure**: `runner_group_name`, `runner_group_token`, `azure_storage_account_name`, `azure_storage_access_key` → Azure VMSS Autoscaled Runner.
2. **Configure Workflows** — Reference the runner group in your workflow configurations to execute jobs on private runners.
3. **Monitor Runners** — Open the runner group URL to view runner status and manage the group.
