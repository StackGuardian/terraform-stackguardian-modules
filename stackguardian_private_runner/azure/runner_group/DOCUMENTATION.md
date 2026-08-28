# StackGuardian Runner Group - Azure Template

Deploy a StackGuardian Runner Group with an Azure Blob Storage backend directly from the
StackGuardian platform.

## Overview

This template provisions everything required to run private runners on Azure: a runner
group on the StackGuardian platform, a resource group and storage account for workflow
artifacts, and an Entra ID identity that lets StackGuardian reach them over OIDC — no
long-lived secret is stored on the platform. Tags are applied automatically to the
StackGuardian resources — see **Tags** below.

Deploying on AWS instead? Use the **StackGuardian Runner Group - AWS** template.

### What This Template Creates

- **Runner Group** — A dedicated group on the StackGuardian platform to organize your
  private runners.
- **Azure Resource Group** — A new resource group hosting the storage account and acting
  as the canonical RG for downstream Azure templates (or use an existing one). Exported as
  `azure_resource_group_name`.
- **Azure Storage Account + private "runner" container** — Storage for workflow outputs
  and artifacts (or point at an existing storage account).
- **Entra ID application + service principal** — Identity for the OIDC connector, granted
  `Storage Blob Data Reader` on the storage account.
- **Azure Connector** — `AZURE_OIDC` integration between StackGuardian and your
  subscription.

## Prerequisites

- A StackGuardian API key for your organization.
- Azure account credentials in your StackGuardian workspace with permissions to create
  Resource Groups, Storage Accounts, Entra ID applications, service principals, and role
  assignments. By default the template creates a new Resource Group; disable **Create
  Azure Resource Group** to deploy into an existing one.

## Template Parameters

### Required Parameters

| Parameter | Description | Type |
|-----------|-------------|------|
| API Key | Your organization's API key on the StackGuardian Platform (`sgu_*`/`sgo_*`) or a secret reference (`${secret::SECRET_NAME}`) | Password |

When **Create Azure Resource Group** is disabled, **Azure Resource Group Name** becomes
required.

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| API Region | Your StackGuardian platform region (EU1 / US1 / DASH) | EU1 - Europe |
| Organization Name | Your organization name (auto-detected from environment if omitted) | Auto-detected |
| Azure Region | The Azure region where storage resources will be deployed | westeurope |
| Create Azure Resource Group | Create a new Azure Resource Group for the storage account | Enabled |
| Azure Resource Group Name | Resource Group name. Optional override when creating; required when using an existing RG | — |
| Create Blob Reader Role Assignment | Grant the OIDC connector SP `Storage Blob Data Reader` on the storage account. Disable when the deploying identity lacks role-assignment write permission | Enabled |
| Create Storage Backend | Whether to create a new Azure Storage Account | Enabled |
| Azure Storage — Account Tier | Performance tier of the Storage Account (Standard / Premium) | Standard |
| Azure Storage — Replication Type | Replication strategy (LRS / GRS / RAGRS / ZRS) | LRS |
| Existing Azure Storage Account Name | Name of an existing Storage Account to use (when not creating new) | — |
| Existing Azure Storage Account Access Key | Access key for that account (sensitive) | — |
| Global Prefix | Prefix for the runner group and connector names. Leave empty to omit it | SG_RUNNER |
| Runner Group Name | Name half of the runner group; the full name is `{prefix}-{name}` | 6-character random string |
| Connector Name | Name half of the connector | Same as the runner group |
| Maximum Runners | Maximum number of runners allowed in the group | 3 |

## Important Notes

**Azure Resource Group**: By default the template **creates a new Resource Group** and
exports its name as `azure_resource_group_name` for downstream Azure templates to consume.
Disable **Create Azure Resource Group** if you prefer to deploy into an existing one.

**Role Assignments**: Creating the `Storage Blob Data Reader` assignment requires
`Microsoft.Authorization/roleAssignments/write` (e.g. `Owner` or `User Access
Administrator`). If the deploying identity only has `Contributor`, disable **Create Blob
Reader Role Assignment** and create the assignment out of band using the
**Azure Connector Service Principal Object ID** output — runners cannot read from the
storage account until it exists.

**API Key Security**: The API key is stored securely and used only to authenticate with
the StackGuardian platform. It must be `sgu_*` (user key), `sgo_*` (organization key), or
a `${secret::SECRET_NAME}` reference.

**Storage Backend Options**: You can either create a new storage account (recommended) or
point to an existing one. When using an existing account, ensure it has the appropriate
permissions and CORS configuration, and a private container named `runner`.

**Resource Naming**: The runner group and the connector are named `{prefix}-{name}`, or
just `{name}` when **Global Prefix** is empty. Leave **Runner Group Name** empty and the
name half is a 6-character random string, which is all the uniqueness a runner group
needs. Set it when you want a stable, project-specific name. The connector shares the
runner group's name — they live in separate API namespaces, so there is nothing to clash
with. The subscription ID used to sit in these names and cost 36 characters; it is a tag
now. The Azure resources keep their own scheme, and Azure naming rules force some
sanitization — the prefix is lowercased and underscores become dashes, and the storage
account name is truncated to fit the 24-character global limit.

**Tags**: The platform models tags as a flat list of strings — there are no keys — capped
at 10. The runner group and the connector both get `StackGuardian Private Runner`,
`Managed by IaC`, `azure`, the subscription ID, the **Global Prefix**, and the region. The
organization name and the runner group's own name are deliberately not tagged: a runner
group only ever lives in one org, and its name is not information a tag adds.

**Data Retention**: The Azure Storage Account is destroyed along with its contents on
`terraform destroy` — back up anything you need first.

## Outputs

| Output | Description |
|--------|-------------|
| Runner Group Name | Name of the created runner group, used in workflow configurations |
| Runner Group Token | Authentication token for registering runners (sensitive) |
| Runner Group URL | Direct link to manage the runner group in the StackGuardian console |
| Connector Name | Name of the Azure connector integration |
| Azure Connector Service Principal Object ID | Object ID of the OIDC connector SP — use to create the role assignment out of band when disabled |
| Azure Resource Group Name | Name of the Resource Group — feed into downstream Azure templates |
| Azure Resource Group Location | Location of the Resource Group |
| Azure Storage Account Name | Name of the Storage Account |
| Azure Storage Account ID | Resource ID of the Storage Account — scope role assignments to it |
| Azure Storage Access Key | Access key for the Storage Account (sensitive) |
| Runner Group ID | Identifier of the runner group (same value as the name) |
| Connector ID | Identifier of the Azure connector (same value as the name) |
| Azure Location | Resolved Azure region |
| SG Org Name | Resolved StackGuardian organization name |
| SG API URI | Resolved StackGuardian API endpoint |

## Security Features

- **Private storage** — The Storage Account disables nested public items and enforces TLS
  1.2 minimum; the `runner` container is private.
- **Federated identity** — The connector uses OIDC federation, so no long-lived secret is
  stored on the platform.
- **Scoped access** — The connector service principal is granted only `Storage Blob Data
  Reader`, on the one storage account.
- **CORS protection** — The storage account accepts browser requests only from the
  StackGuardian platform origin.
- **Sensitive output protection** — Runner registration tokens and storage access keys are
  marked sensitive.

## Usage

After deploying this template, use the outputs to:

1. **Deploy Runners** — Pass `runner_group_name`, `runner_group_token`,
   `azure_resource_group_name`, `azure_storage_account_name`, and
   `azure_storage_access_key` to the Azure Runner / Azure VMSS Autoscaled Runner template.
2. **Configure Workflows** — Reference the runner group in your workflow configurations to
   execute jobs on private runners.
3. **Monitor Runners** — Open the runner group URL to view runner status and manage the
   group.
