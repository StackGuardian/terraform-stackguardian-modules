# StackGuardian Runner Group - Azure

> Part of [StackGuardian Private Runner](../../README.md) — [Azure stack overview](../DOCUMENTATION.md) · [platform template doc](DOCUMENTATION.md)

Provisions a StackGuardian Runner Group with an Azure Blob Storage backend and the
`AZURE_OIDC` connector the platform uses to reach it.

This module requires **only** the Azure providers (`azurerm`, `azuread`). The
platform-side resources (runner group, connector, registration token) live in the shared,
cloud-agnostic [`runner_group/`](../../runner_group/) module, which this module calls — so
an Azure deployment never initializes the AWS provider. The AWS equivalent is
[`aws/runner_group/`](../../aws/runner_group/).

## What Gets Created

- **Resource Group** hosting the storage account, and acting as the canonical RG for the
  downstream `azure/*` modules (when `create_azure_resource_group = true`). Its name is
  exported as `azure_resource_group_name`.
- **Storage Account + private `runner` blob container** with TLS 1.2 minimum and CORS
  limited to the StackGuardian platform origin (when `create_storage_backend = true`).
  The container name `runner` is required by the platform.
- **Entra ID application + service principal** backing the OIDC connector.
- **Federated identity credential** issued by the StackGuardian API URI for the org
  subject `/orgs/{org_name}` — no long-lived secret is stored on the platform.
- **`Storage Blob Data Reader` role assignment** on the storage account (when
  `create_blob_reader_role_assignment = true`).
- **StackGuardian Runner Group** with `max_number_of_runners` and default tags.
- **StackGuardian Connector** (`AZURE_OIDC`) wired to the identity above.

## Prerequisites

- StackGuardian API key (`sgu_*` user key, `sgo_*` org key, or a `${secret::SECRET_NAME}`
  reference).
- OpenTofu >= 1.7 or Terraform >= 1.3.
- Azure credentials (CLI / service principal) with permission to create Resource Groups,
  Storage Accounts, Entra ID applications, service principals, and role assignments.
  Creating the role assignment needs `Microsoft.Authorization/roleAssignments/write`
  (e.g. `Owner` or `User Access Administrator`); if the deploying identity lacks it, set
  `create_blob_reader_role_assignment = false` and create the assignment out of band using
  the `azure_connector_service_principal_object_id` output.

## Quick Start

`terraform.tfvars`:

```hcl
stackguardian = {
  api_key  = "sgu_your_api_key_here"
  api_uri  = "https://api.app.stackguardian.io"
  org_name = "your-org-name"
}

azure_location = "westeurope"

# Optional — when omitted the module creates a resource group named
# "{sanitized_prefix}-rg-{subscription_id}".
# azure_resource_group_name = "my-resource-group"
```

```bash
tofu init
tofu plan
tofu apply
```

### As a module

```hcl
module "runner_group" {
  source = "./stackguardian_private_runner/azure/runner_group"

  stackguardian = {
    api_key = "sgu_your_api_key"
  }

  azure_location = "westeurope"
  max_runners    = 3
}
```

## Configuration

### Required Parameters

| Parameter | Description | Type |
|-----------|-------------|------|
| `stackguardian.api_key` | StackGuardian API key (must start with `sgu_` or `sgo_`) | `string` (sensitive) |

When `create_azure_resource_group = false`, `azure_resource_group_name` becomes required.

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `stackguardian.api_uri` | StackGuardian API endpoint (EU1 / US1 / DASH) | `https://api.app.stackguardian.io` |
| `stackguardian.org_name` | Organization name; falls back to the `SG_ORG_ID` env var | `""` |
| `azure_location` | Azure region for the resource group and storage account | `westeurope` |
| `create_azure_resource_group` | Create a new resource group | `true` |
| `azure_resource_group_name` | Name override when creating; the existing RG name when not | `""` |
| `create_storage_backend` | Create a new Storage Account | `true` |
| `existing_azure_storage_account_name` | Existing Storage Account name (when `create_storage_backend = false`) | `""` |
| `existing_azure_storage_account_access_key` | Access key for that account (sensitive) | `""` |
| `azure_storage.account_tier` | Storage Account performance tier (`Standard` / `Premium`) | `Standard` |
| `azure_storage.account_replication_type` | Replication strategy (`LRS` / `GRS` / `RAGRS` / `ZRS`) | `LRS` |
| `create_blob_reader_role_assignment` | Grant the connector SP `Storage Blob Data Reader` | `true` |
| `override_names.global_prefix` | Prefix for the runner group and connector names; `""` omits it | `SG_RUNNER` |
| `override_names.runner_group_name` | Name half of the runner group | (6-char random) |
| `override_names.connector_name` | Name half of the connector | (runner group's name) |
| `max_runners` | Maximum runners allowed in the group | `3` |

### Naming

The runner group and the connector are named `{global_prefix}-{name}`, or just
`{name}` when `global_prefix` is empty. `name` is whatever you pass as
`override_names.runner_group_name`; left empty it is a 6-character random string,
which is all the uniqueness a runner group needs.

- Runner group: `{global_prefix}-{name}` — e.g. `SG_RUNNER-k3m9xz`
- Connector: same name as the runner group (separate API namespaces, so no clash)

The subscription ID is **not** in the name — it is a tag. It used to cost 36 of the
name's characters while telling you nothing you could not read off the tags.

Azure resources keep their own scheme, since Azure naming rules force sanitization
(the prefix is lowercased and underscores become dashes):

- Resource group: `{sanitized_prefix}-rg-{subscription_id}`
- Storage account: `stgbackend{prefix}` truncated to 16 chars + an 8-char random suffix
  (the 24-char, lowercase-alphanumeric global limit)
- Entra ID application: `{global_prefix}-sg-connector`


### Tags

The platform models tags as a flat list of strings — there are no keys — capped at
10. Both the runner group and the connector get:

| Tag | Example |
|-----|---------|
| Purpose marker | `StackGuardian Private Runner` |
| Provisioner | `Managed by IaC` |
| Cloud | `azure` |
| Subscription ID | `a97621d8-9158-4681-81b6-38b1222afba4` |
| Naming prefix | `SG_RUNNER` |
| Region | `germanywestcentral` |

The org name and the runner group name are deliberately not tagged: a runner group
only ever lives in one org, and its own name is not information a tag adds.

## Outputs

| Output | Description |
|--------|-------------|
| `runner_group_name` / `runner_group_id` | Name of the created runner group |
| `runner_group_token` | Registration token for runners (sensitive) |
| `runner_group_url` | Direct link to the runner group in the web console |
| `connector_name` / `connector_id` | Name of the Azure connector |
| `azure_connector_service_principal_object_id` | Connector SP object ID — use it to create the role assignment out of band |
| `azure_resource_group_name` | Resource group name — feed into the downstream `azure/*` modules |
| `azure_resource_group_location` | Resource group region |
| `azure_storage_account_name` | Storage backend account name |
| `azure_storage_account_id` | Storage account resource ID (`null` when using an existing account) — scope role assignments to it |
| `azure_storage_access_key` | Storage account access key (sensitive) |
| `sg_org_name` / `sg_api_uri` / `azure_location` | Resolved platform and region settings |

Feed `runner_group_name`, `runner_group_token`, and `azure_resource_group_name` into
[`azure/azure_runner`](../azure_runner/) or [`azure/vmss`](../vmss/). See
[`examples/azure/quickstart`](../../examples/azure/quickstart/) for the whole stack wired
together.

## Security Notes

- The storage account disables public blob access and enforces TLS 1.2 minimum; the
  container is private.
- Browser requests are accepted only from the StackGuardian console origin (CORS).
- The connector authenticates by OIDC federation, so no client secret is stored on the
  platform.
- The connector service principal gets only `Storage Blob Data Reader`, scoped to the one
  storage account.
- The runner registration token and the storage access key are marked sensitive.
- `tofu destroy` removes the storage account and everything in it. Back up anything you
  need first.
