# StackGuardian Runner Group - AWS or Azure Module

This Terraform module provisions a StackGuardian Runner Group with a cloud storage backend (AWS S3 or Azure Blob Storage) and the corresponding StackGuardian connector for secure access from the StackGuardian platform.

## Overview

The module creates everything required to host private runners against either AWS or Azure. A single `cloud_provider` toggle drives which storage backend, connector kind, and authentication path are provisioned. AWS deployments use a cross-account IAM role (RBAC connector); Azure deployments use OIDC federation with an auto-provisioned Azure AD application and service principal.

### What Gets Created

**StackGuardian Platform Resources (always):**
- **StackGuardian Runner Group** — Platform resource for organizing private runners, with `max_number_of_runners`, default tags, and the resolved storage backend configuration.
- **StackGuardian Connector** — Cloud-specific connector for storage access:
  - **AWS**: `AWS_RBAC` connector using cross-account IAM role + external ID.
  - **Azure**: `AZURE_OIDC` connector using federated identity from a SG-issued OIDC token.

**AWS-only resources (when `cloud_provider = "aws"`):**
- **S3 bucket** with public access block and CORS limited to the StackGuardian platform origin (created when `create_storage_backend = true`).
- **IAM role + policy** scoped to the bucket; trust policy allows StackGuardian AWS accounts (`163602625436`, `476299211833`) and the caller's account, gated by an external ID (`{org_name}:{24-char-random}`).

**Azure-only resources (when `cloud_provider = "azure"`):**
- **Resource Group** to host the storage account and act as the canonical RG for downstream Azure modules (created when `create_azure_resource_group = true`, the default). Its name is exported as `azure_resource_group_name`.
- **Storage Account + private `runner` blob container** with TLS 1.2 minimum and CORS limited to the StackGuardian platform origin (created when `create_storage_backend = true`).
- **Azure AD application + service principal** for the OIDC connector.
- **Federated identity credential** issued by the StackGuardian API URI for the org subject `/orgs/{org_name}`.
- **`Storage Blob Data Reader` role assignment** scoped to the storage account (created when `create_blob_reader_role_assignment = true`, the default — requires the Terraform identity to have `Microsoft.Authorization/roleAssignments/write`, e.g. `Owner` or `User Access Administrator`).

## Prerequisites

- StackGuardian API key (`sgu_*` user key, `sgo_*` org key, or a `${secret::SECRET_NAME}` reference).
- Terraform >= 1.0 or OpenTofu >= 1.7.
- For AWS: AWS credentials with permissions to create S3 buckets and IAM roles.
- For Azure: Azure credentials (CLI / SP) with permissions to create Resource Groups, Storage Accounts, Azure AD applications, service principals, and role assignments. By default the module creates a new Resource Group; set `create_azure_resource_group = false` and pass `azure_resource_group_name` to deploy into an existing one.

## Quick Start

### Step 1: Configure Variables

#### AWS Example — `terraform.tfvars`

```hcl
cloud_provider = "aws"

stackguardian = {
  api_key  = "sgu_your_api_key_here"
  api_uri  = "https://api.app.stackguardian.io"
  org_name = "your-org-name"
}

aws_region = "eu-central-1"
```

#### Azure Example — `terraform.tfvars`

```hcl
cloud_provider = "azure"

stackguardian = {
  api_key  = "sgu_your_api_key_here"
  api_uri  = "https://api.app.stackguardian.io"
  org_name = "your-org-name"
}

azure_location = "westeurope"
# Optional — when omitted the module creates a new resource group named
# "{effective_prefix}-rg-{subscription_id}" (lowercased, dashes).
# azure_resource_group_name = "my-resource-group"
```

### Step 2: Deploy

```bash
terraform init
terraform plan
terraform apply
```

### Basic Configuration Examples

#### AWS

```hcl
module "runner_group" {
  source = "./stackguardian_runner_group"

  cloud_provider = "aws"

  stackguardian = {
    api_key = "sgu_your_api_key"
  }

  aws_region = "eu-central-1"
}
```

#### Azure

```hcl
module "runner_group" {
  source = "./stackguardian_runner_group"

  cloud_provider = "azure"

  stackguardian = {
    api_key = "sgu_your_api_key"
  }

  azure_location = "westeurope"
}
```

## Configuration

### Required Parameters

| Parameter | Description | Type |
|-----------|-------------|------|
| `stackguardian.api_key` | StackGuardian API key (must start with `sgu_` or `sgo_`) | `string` (sensitive) |

When `cloud_provider = "azure"`, the module creates a new Azure Resource Group by default. Set `create_azure_resource_group = false` and provide `azure_resource_group_name` to deploy into an existing resource group instead.

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `cloud_provider` | Cloud provider for the storage backend (`aws` or `azure`) | `aws` |
| `stackguardian.api_uri` | StackGuardian API endpoint (EU1 / US1 / DASH) | `https://api.app.stackguardian.io` |
| `stackguardian.org_name` | Organization name; falls back to `SG_ORG_ID` env var | `""` |
| `aws_region` | Target AWS region (used when `cloud_provider = "aws"`) | `eu-central-1` |
| `azure_location` | Azure region (used when `cloud_provider = "azure"`) | `westeurope` |
| `create_azure_resource_group` | Create a new Azure Resource Group for the storage account (Azure only) | `true` |
| `create_blob_reader_role_assignment` | Grant the OIDC connector SP `Storage Blob Data Reader` on the storage account (Azure only). Disable when the runner SP lacks role-assignment write permission | `true` |
| `azure_resource_group_name` | Resource Group name. Optional override when creating; required when using an existing RG | `""` |
| `create_storage_backend` | Create a new storage backend (S3 bucket / Storage Account) | `true` |
| `existing_s3_bucket_name` | Existing S3 bucket name (AWS, when `create_storage_backend = false`) | `""` |
| `existing_azure_storage_account_name` | Existing Azure Storage Account name (Azure, when `create_storage_backend = false`) | `""` |
| `existing_azure_storage_account_access_key` | Access key for the existing Azure Storage Account (sensitive) | `""` |
| `force_destroy_storage_backend` | Force destroy the S3 bucket on `terraform destroy` (AWS only) | `false` |
| `azure_storage.account_tier` | Storage Account performance tier (`Standard` / `Premium`) | `Standard` |
| `azure_storage.account_replication_type` | Replication strategy (`LRS` / `GRS` / `RAGRS` / `ZRS`) | `LRS` |
| `override_names.global_prefix` | Prefix for resource naming | `SG_RUNNER` |
| `override_names.include_org_in_prefix` | Append org name to the prefix (e.g. `SG_RUNNER_demo-org`) | `false` |
| `override_names.runner_group_name` | Override the runner group name | Auto-generated |
| `override_names.connector_name` | Override the connector name | Auto-generated |
| `max_runners` | Maximum runners allowed in the runner group (>= 1) | `3` |

### Configuration Examples

#### AWS — Advanced

```hcl
module "runner_group" {
  source = "./stackguardian_runner_group"

  cloud_provider = "aws"

  stackguardian = {
    api_key  = var.sg_api_key
    api_uri  = "https://api.us.stackguardian.io"
    org_name = "my-organization"
  }

  aws_region                    = "us-east-1"
  create_storage_backend        = true
  force_destroy_storage_backend = false
  max_runners                   = 10

  override_names = {
    global_prefix         = "PROD_RUNNER"
    include_org_in_prefix = true
    runner_group_name     = "production-runners"
    connector_name        = "prod-s3-connector"
  }
}
```

#### AWS — Using an Existing S3 Bucket

```hcl
module "runner_group" {
  source = "./stackguardian_runner_group"

  cloud_provider = "aws"

  stackguardian = {
    api_key = var.sg_api_key
  }

  aws_region              = "eu-central-1"
  create_storage_backend  = false
  existing_s3_bucket_name = "my-existing-bucket"
}
```

#### Azure — Advanced

```hcl
module "runner_group" {
  source = "./stackguardian_runner_group"

  cloud_provider = "azure"

  stackguardian = {
    api_key  = var.sg_api_key
    org_name = "my-organization"
  }

  azure_location              = "germanywestcentral"
  create_azure_resource_group = true
  azure_resource_group_name   = "rg-stackguardian" # optional name override for the new RG

  azure_storage = {
    account_tier             = "Standard"
    account_replication_type = "ZRS"
  }

  max_runners = 10

  override_names = {
    global_prefix         = "PROD_RUNNER"
    include_org_in_prefix = true
  }
}
```

#### Azure — Using an Existing Storage Account

```hcl
module "runner_group" {
  source = "./stackguardian_runner_group"

  cloud_provider = "azure"

  stackguardian = {
    api_key = var.sg_api_key
  }

  azure_location                            = "westeurope"
  create_azure_resource_group               = false
  azure_resource_group_name                 = "my-existing-rg"
  create_storage_backend                    = false
  existing_azure_storage_account_name       = "myexistingstorage"
  existing_azure_storage_account_access_key = var.azure_storage_key
}
```

## Usage

### Deployment Commands

```bash
terraform init
terraform plan
terraform apply

terraform output runner_group_name
terraform output -raw runner_group_token   # sensitive
```

### Cleanup

```bash
terraform destroy
```

**Warning (AWS)**: With `force_destroy_storage_backend = false` (default), the S3 bucket will not be deleted while it contains objects. Empty the bucket or set `force_destroy_storage_backend = true`.

**Warning (Azure)**: The Storage Account is deleted along with all blob containers and contents. The Azure AD application and service principal are also removed.

## Architecture

### Resource Organization

| File | Purpose |
|------|---------|
| `provider.tf` | `terraform { required_providers }` and provider blocks (AWS, Azure RM, Azure AD, StackGuardian, external, random) |
| `variables.tf` | Input variable definitions and validations |
| `locals.tf` | Computed values, naming, and per-cloud branching |
| `data.tf` | Data sources: SG runner group token, env extraction, AWS caller identity, Azure client config |
| `runner_group.tf` | StackGuardian runner group resource (selects AWS or Azure storage backend config) |
| `connector.tf` | StackGuardian connector — AWS RBAC and Azure OIDC variants |
| `storage_backend.tf` | AWS S3 bucket, public access block, CORS configuration |
| `storage_backend_role.tf` | AWS IAM role, policy, and external ID |
| `storage_backend_azure.tf` | Azure Storage Account, blob container, Azure AD app/SP, federated identity, role assignment |
| `outputs.tf` | Module outputs |

### Resource Naming Convention

Resources follow `{effective_prefix}-{resource-type}-{account_identifier}`:

- `effective_prefix`: `global_prefix` (default `SG_RUNNER`); when `include_org_in_prefix = true` and an org name is available, becomes `{global_prefix}_{org_name}`.
- `account_identifier`: AWS account ID (AWS) or Azure subscription ID (Azure).

Examples:
- Runner group: `SG_RUNNER-runner-group-123456789012`
- AWS connector: `SG_RUNNER-private-runner-backend-123456789012`
- AWS IAM role: `SG_RUNNER-private-runner-s3-role`
- Azure storage account: `stgbackend{prefix}{8-char-random}` (lowercase, max 24 chars)
- Azure AD application: `SG_RUNNER-sg-connector`

### Security Model

- **AWS cross-account access**: IAM role trust policy allows StackGuardian platform accounts and the caller's account to assume the role; an external ID (`{org_name}:{24-char-random}`) prevents confused-deputy attacks. IAM policy is scoped to the specific bucket and required S3 actions only. The bucket has public access blocked and CORS limited to the SG platform origin.
- **Azure OIDC federation**: A federated identity credential issued by `var.stackguardian.api_uri` for subject `/orgs/{org_name}` lets the SG platform assume the service principal — no static secret. The SP is granted only `Storage Blob Data Reader` on the storage account. Storage Account enforces TLS 1.2 minimum and disables nested public items; CORS is limited to the SG platform origin.

## Troubleshooting

### Common Issues

1. **API Key Validation Error**
   - Ensure the API key matches `^(sg[uo]_.*|\$\{secret::[A-Za-z0-9_-]+\})$` — i.e. starts with `sgu_` / `sgo_` or is a `${secret::...}` reference.
2. **Organization Name Not Found**
   - Provide `stackguardian.org_name` explicitly, or set `SG_ORG_ID` in the environment (the module extracts everything after the last `/`).
3. **AWS — S3 bucket already exists**
   - Bucket names are globally unique; the module uses an 8-char random prefix when creating new buckets. To use an existing bucket, set `create_storage_backend = false` and `existing_s3_bucket_name`.
4. **AWS — Permission denied on destroy**
   - Empty the bucket or set `force_destroy_storage_backend = true`.
5. **Azure — Resource group not found**
   - When `create_azure_resource_group = false`, `azure_resource_group_name` must reference an **existing** resource group. With the default `create_azure_resource_group = true`, the module creates the RG itself.
6. **Azure — Existing storage account access key invalid**
   - When `create_storage_backend = false`, `existing_azure_storage_account_access_key` must be a primary or secondary key of `existing_azure_storage_account_name`.
7. **Azure — Insufficient privileges to register an Azure AD application**
   - The OIDC connector creates an Azure AD application + SP. The caller needs Application.ReadWrite.OwnedBy or equivalent.
8. **Azure — `AuthorizationFailed` on `Microsoft.Authorization/roleAssignments/write`**
   - The Terraform identity lacks permission to create role assignments. Either grant it `Owner` / `User Access Administrator` at the subscription or RG scope, or set `create_blob_reader_role_assignment = false` and create the role assignment out of band using `azure_connector_service_principal_object_id` and `azure_storage_account_name`.

### Debugging Commands

```bash
terraform state list
terraform state show stackguardian_runner_group.this
terraform state show 'stackguardian_connector.aws[0]'   # AWS
terraform state show 'stackguardian_connector.azure[0]' # Azure

export TF_LOG=DEBUG
terraform apply
```

## Outputs

| Output | Description |
|--------|-------------|
| `runner_group_name` | Name of the StackGuardian runner group |
| `runner_group_id` | ID of the StackGuardian runner group |
| `runner_group_token` | Token for runner registration (sensitive) |
| `runner_group_url` | Direct URL to the runner group in the StackGuardian web console |
| `connector_name` | Name of the StackGuardian connector (AWS or Azure) |
| `connector_id` | ID of the StackGuardian connector (AWS or Azure) |
| `connector_external_id` | External ID for cross-account S3 access (AWS only; empty on Azure) |
| `s3_bucket_name` | Name of the S3 bucket (AWS only) |
| `s3_bucket_arn` | ARN of the S3 bucket (AWS only) |
| `storage_backend_role_arn` | ARN of the IAM role for storage backend access (AWS only) |
| `storage_backend_role_name` | Name of the IAM role (AWS only) |
| `azure_resource_group_name` | Azure Resource Group name (Azure only) — pass to downstream `azure/*` modules |
| `azure_resource_group_location` | Azure Resource Group location (Azure only) |
| `azure_connector_service_principal_object_id` | Object ID of the OIDC connector service principal (Azure only) — use to create the role assignment out of band when `create_blob_reader_role_assignment = false` |
| `azure_storage_account_name` | Azure Storage Account name (Azure only) |
| `azure_storage_access_key` | Azure Storage Account primary access key (Azure only, sensitive) |
| `cloud_provider` | The cloud provider used for the storage backend |
| `azure_location` | Azure region (Azure only) |
| `aws_region` | AWS region (AWS only) |
| `sg_org_name` | StackGuardian organization name |
| `sg_api_uri` | StackGuardian API URI |

## Security Considerations

- **API Key Storage** — keep the StackGuardian API key in a secrets manager or use the `${secret::...}` reference syntax.
- **AWS IAM least privilege** — the generated IAM policy grants only the S3 actions required by runners on the specific bucket; the trust policy is gated by an external ID.
- **AWS bucket hardening** — public access is blocked; CORS allows only the StackGuardian platform origin.
- **Azure OIDC** — no long-lived secrets are stored; the connector uses federated identity for the SG org subject.
- **Azure storage hardening** — TLS 1.2 minimum, nested public items disabled, CORS limited to the SG platform origin, blob container is private.
- **Sensitive outputs** — `runner_group_token` and `azure_storage_access_key` are marked sensitive; treat them accordingly when wiring into downstream modules.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| stackguardian | >= 1.3.3 |
| aws | >= 4.0 |
| azurerm | >= 3.0 |
| azuread | >= 2.0 |
| external | >= 2.0 |
| random | >= 3.0 |

## Next Steps

After deploying this module:

1. Use `runner_group_name` and `runner_group_token` with the runner deployment modules (`aws_autoscaled_runner`, `aws_runner`, or the Azure VMSS autoscaler) to register runners.
2. Pass `storage_backend_role_arn` + `s3_bucket_name` (AWS) or `azure_storage_account_name` + `azure_storage_access_key` (Azure) into the runner modules.
3. Open the runner group in the StackGuardian web console using `runner_group_url`.

## Support

- [StackGuardian Documentation](https://docs.stackguardian.io/)
- [StackGuardian Terraform Provider](https://registry.terraform.io/providers/StackGuardian/stackguardian/latest/docs)
- [GitHub Issues](https://github.com/StackGuardian/terraform-stackguardian-modules/issues)
