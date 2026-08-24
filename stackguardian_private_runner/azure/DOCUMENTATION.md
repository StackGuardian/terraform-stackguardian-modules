# StackGuardian Private Runner - Azure Full Stack Template

Deploy a complete auto-scaling StackGuardian Private Runner infrastructure on Azure using the StackGuardian platform.

## Overview

This Stack deploys a production-ready private runner environment with custom managed image building, an auto-scaling VM Scale Set, and an Azure Function-based autoscaler. The Stack orchestrates four Azure templates plus the shared `runner_group` template, which work together to provide a fully managed runner infrastructure inside your own subscription.

### What This Stack Creates

- **Custom Managed Image** with pre-installed Docker, Terraform, OpenTofu, and StackGuardian runner components
- **Runner Group** on StackGuardian platform with Azure Blob Storage backend and an Entra ID (OIDC) connector
- **VM Scale Set** with Linux instances that automatically register as runners
- **Function App Autoscaler** (Flex Consumption, Python 3.11) that monitors job queues and adjusts VMSS capacity
- **Network Infrastructure** (optional) including VNet, subnet, NSG, and a NAT Gateway for private deployments
- **Managed Identities and Role Assignments** for the runner instances, the autoscaler function, and blob storage access

## Prerequisites

- StackGuardian organization API key (`sgo_*` or `sgu_*`)
- Azure subscription with Contributor permissions (User Access Administrator as well, if the templates should create role assignments for you)
- Azure CLI authenticated (`az login`) on the machine or runner executing the apply — Packer, the Function App code deployment, and image cleanup all shell out to `az`
- A Resource Group for the runner infrastructure (the `runner_group` template can create one for you)
- A User-Assigned Managed Identity that the runner VMs will use to read the storage backend (see [Managed identity model](#managed-identity-model))
- Outbound internet access for the runner instances (NAT Gateway, Azure Firewall, or an HTTP proxy)
- OpenTofu >= 1.4 (`tofu`) or Terraform >= 1.4 — the `packer` template records the built image in state via `terraform_data`, which needs 1.4+. Everything here is plain HCL, so `terraform` works identically if that is what you have.
- Local tooling on the executing machine: `az`, `git`, `zip`, and `wget` (the Packer bootstrap downloads the Packer binary itself)

---

## Template 1: Packer Image Builder

Build a custom Azure managed image for the StackGuardian Private Runner with pre-installed dependencies.

The image is built **once**. Packer runs on the first apply, the resulting image resource ID is recorded in state (`terraform_data.image_id`), and every following plan reuses it — repeated applies cost no build time. To build a fresh image, change `packer_config.rebuild_image_token` to any new value; that triggers exactly one rebuild, and the new value then sits there without rebuilding again.

### Required Parameters

| Parameter | Description | Type |
|-----------|-------------|------|
| resource_group_name | Resource group where the managed image is stored | string |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| azure_location | Azure region where the image is built | `westeurope` |
| create_resource_group | Create the resource group (if false, it must already exist) | `false` |
| vm_size | VM size used for the Packer build VM | `Standard_D2s_v3` |
| image_name_prefix | Prefix for the generated image name | `sg-runner` |
| network.vnet_name | Existing VNet for the build VM (empty = Packer creates temporary networking) | `""` |
| network.subnet_name | Existing subnet inside that VNet | `""` |
| network.resource_group_name | Resource group of the existing VNet, if different | `""` |
| network.proxy_url | HTTP proxy URL forwarded to the build VM | `""` |
| os.publisher | Base image publisher — `Canonical` or `RedHat` | `Canonical` |
| os.offer | Base image offer | `0001-com-ubuntu-server-jammy` |
| os.sku | Base image SKU | `22_04-lts-gen2` |
| os.version | Base image version | `latest` |
| os.update_os_before_install | Update OS packages before installing components | `true` |
| os.user_script | Custom shell script to execute during provisioning | `""` |
| packer_config.version | Packer version to download and use | `1.14.1` |
| packer_config.rebuild_image_token | Change to any new value to build a fresh image (otherwise built once and reused from state) | `""` |
| packer_config.cleanup_images_on_destroy | Delete this deployment's image on destroy | `true` |
| terraform.primary_version | Primary Terraform version to install | `""` |
| terraform.additional_versions | Additional Terraform versions to install | `[]` |
| opentofu.primary_version | Primary OpenTofu version to install | `""` |
| opentofu.additional_versions | Additional OpenTofu versions to install | `[]` |

There is no `ssh_username` input — the build user is derived from `os.publisher` (`ubuntu` for Canonical, `azureuser` for RedHat).

### Outputs

| Output | Description |
|--------|-------------|
| image_id | Resource ID of the managed image recorded in state |
| image_info | Comprehensive image information for tracking |
| resource_group_name | Resource group where the image is stored |
| cleanup_commands | Ready-made `az image` commands for manual cleanup |

---

## Template 2: Runner Group (shared)

Create a StackGuardian Runner Group with an Azure Blob Storage backend and an Entra ID OIDC connector. This is the shared `runner_group/` template at the repository root, driven into Azure mode with `cloud_provider = "azure"`; the same template serves the AWS stack.

### Required Parameters

| Parameter | Description | Type |
|-----------|-------------|------|
| cloud_provider | Must be set to `azure` (defaults to `aws`) | string |
| stackguardian.api_key | Your organization's API key (`sgo_*`/`sgu_*`) or secret reference | string |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| stackguardian.api_uri | StackGuardian platform region | `https://api.app.stackguardian.io` |
| stackguardian.org_name | Your organization name | (from `SG_ORG_ID` environment) |
| azure_location | Azure region for the storage account and resource group | `westeurope` |
| create_azure_resource_group | Create the resource group that hosts the storage account | `true` |
| azure_resource_group_name | Name override when creating, or the existing RG name when not creating | (derived from prefix) |
| create_storage_backend | Create a new Storage Account | `true` |
| existing_azure_storage_account_name | Existing Storage Account name (when `create_storage_backend` is false) | `""` |
| existing_azure_storage_account_access_key | Access key for that existing account (sensitive) | `""` |
| azure_storage.account_tier | Storage Account performance tier | `Standard` |
| azure_storage.account_replication_type | Replication strategy (LRS, GRS, RAGRS, ZRS) | `LRS` |
| create_blob_reader_role_assignment | Grant the connector service principal `Storage Blob Data Reader` | `true` |
| override_names.global_prefix | Prefix for naming all resources | `SG_RUNNER` |
| override_names.include_org_in_prefix | Append organization name to prefix | `false` |
| override_names.runner_group_name | Override the runner group name | (auto-generated) |
| max_runners | Maximum number of runners allowed in the group | `3` |

`override_names.connector_name` exists but only names the AWS connector; the Azure connector name is derived from the effective prefix.

### Outputs

| Output | Description |
|--------|-------------|
| runner_group_name | Name of the StackGuardian runner group |
| runner_group_token | Token for runner registration (sensitive) |
| runner_group_url | Direct link to the runner group in the web console |
| connector_name | Name of the StackGuardian connector |
| azure_resource_group_name | Resource group hosting the storage account — feed this to the `resource_group_name` input of the Azure templates |
| azure_resource_group_location | Location of that resource group |
| azure_storage_account_name | Name of the Storage Account used as backend |
| azure_storage_access_key | Access key for that Storage Account (sensitive) |
| azure_connector_service_principal_object_id | Object ID of the OIDC connector service principal |
| sg_org_name / sg_api_uri | Resolved organization name and platform API URI |

Set `create_blob_reader_role_assignment = false` when the identity running the apply lacks `Microsoft.Authorization/roleAssignments/write`. In that case, use `azure_connector_service_principal_object_id` to grant `Storage Blob Data Reader` out of band before runners can read the backend.

---

## Template 3: VM Scale Set

Deploy a VM Scale Set whose instances boot from the custom image and register themselves as StackGuardian runners.

### Required Parameters

| Parameter | Description | Type |
|-----------|-------------|------|
| stackguardian.api_key | Your organization's API key | string |
| resource_group_name | Resource group for the scale set | string |
| vm_image_id | Custom image resource ID (from the packer template) | string |
| runner_group_name | Runner group name (from the runner_group template) | string |
| runner_group_token | Runner group token (from the runner_group template) | string |
| storage_backend_identity_id | Resource ID of the User-Assigned Managed Identity used to read the storage backend | string |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| stackguardian.api_uri | StackGuardian platform region | `https://api.app.stackguardian.io` |
| stackguardian.org_name | Your organization name | (from `SG_ORG_ID` environment) |
| azure_location | Azure region for deployment | `westeurope` |
| vm_size | VM size for each scale-set instance | `Standard_D4s_v3` |
| override_names.global_prefix | Prefix for naming all resources | `SG_RUNNER` |
| override_names.include_org_in_prefix | Append organization name to prefix | `false` |
| network.create_network | Create a new VNet and subnet | `false` |
| network.vnet_id | Existing VNet resource ID (required when not creating) | `""` |
| network.subnet_id | Existing subnet resource ID (required when not creating) | `""` |
| network.vnet_address_space | Address space for the new VNet | `["10.0.0.0/16"]` |
| network.subnet_address_prefix | Address prefix for the new subnet | `10.0.1.0/24` |
| network.create_network_infrastructure | Create a NAT Gateway and attach it to the created subnet | `false` |
| network.service_endpoints | VNet service endpoints on the created subnet (e.g. `Microsoft.Storage`) | `[]` |
| network.proxy_url | HTTP proxy URL for private deployments | `""` |
| network.additional_nsg_ids | Additional NSG IDs to associate | `[]` |
| os_disk.caching | OS disk caching mode | `ReadWrite` |
| os_disk.storage_account_type | OS disk type | `Premium_LRS` |
| os_disk.disk_size_gb | OS disk size in GB (min 30) | `100` |
| firewall.admin_username | Linux admin user on each instance | `azureuser` |
| firewall.ssh_public_key | SSH public key to install (preferred) | `""` |
| firewall.generate_ssh_key | Generate an RSA keypair and expose the private key as an output | `false` |
| firewall.ssh_access_rules | Map of source prefixes allowed to reach SSH | `{}` |
| firewall.additional_inbound_rules | Additional NSG inbound rules | `{}` |
| scaling.min_size | Minimum instance count | `1` |
| scaling.max_size | Maximum instance count | `3` |
| scaling.desired_capacity | Initial instance count (ignored on later applies) | `1` |
| upgrade_policy.mode | `Manual`, `Rolling` or `Automatic` model rollout | `Manual` |
| upgrade_policy.health_probe_id | Load Balancer probe used as the health signal | `""` |
| upgrade_policy.application_health_extension | In-guest health extension (`protocol`, `port`, `request_path`) | `null` |
| upgrade_policy.max_batch_instance_percent | Max percent of instances upgraded per batch | `20` |
| upgrade_policy.max_unhealthy_instance_percent | Max percent allowed unhealthy during upgrade | `20` |
| upgrade_policy.max_unhealthy_upgraded_instance_percent | Max percent of upgraded instances allowed unhealthy | `20` |
| upgrade_policy.pause_time_between_batches | ISO 8601 wait between batches | `PT5M` |
| upgrade_policy.automatic_instance_repair | Let Azure replace unhealthy instances | `false` |
| upgrade_policy.automatic_instance_repair_grace_period | ISO 8601 grace period before repairs | `PT30M` |
| runner_startup_timeout | Max seconds to wait for Docker to start | `300` |

Either `firewall.ssh_public_key` or `firewall.generate_ssh_key = true` must be set — the template refuses to build a scale set with no way in. `Rolling`/`Automatic` upgrades and `automatic_instance_repair` each require a health signal: supply `health_probe_id` or `application_health_extension`.

### Outputs

| Output | Description |
|--------|-------------|
| vmss_id | Resource ID of the VM Scale Set |
| vmss_name | Name of the VM Scale Set — feed to the autoscaler's `vmss.name` |
| vmss_resource_group_name | Resource group of the scale set — feed to the autoscaler's `vmss.resource_group_name` |
| network_security_group_id | ID of the network security group |
| vnet_id / subnet_id | IDs of the VNet and subnet (created or existing) |
| ssh_private_key | Generated SSH private key, when `generate_ssh_key = true` (sensitive) |
| ssh_public_key | SSH public key installed on the instances |
| storage_backend_identity_id | Pass-through of the managed identity ID |

---

## Template 4: Autoscaler

Deploy an Azure Function App that monitors StackGuardian job queues and scales the VM Scale Set.

### Required Parameters

| Parameter | Description | Type |
|-----------|-------------|------|
| stackguardian.api_key | Your organization's API key | string |
| resource_group_name | Existing resource group for the autoscaler resources | string |
| vmss.name | Name of the VM Scale Set to manage (from the vmss template) | string |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| stackguardian.api_uri | StackGuardian platform region | `https://api.app.stackguardian.io` |
| stackguardian.org_name | Your organization name | (from `SG_ORG_ID` environment) |
| azure_location | Azure region for the Function App | `westeurope` |
| vmss.resource_group_name | Resource group of the scale set | (falls back to `resource_group_name`) |
| override_names.global_prefix | Prefix for naming all resources | `SG_RUNNER` |
| override_names.include_org_in_prefix | Append organization name to prefix | `false` |
| override_names.runner_group_name | Runner group the autoscaler queries — set this to the runner group name | `""` |
| scaling.min_runners | Minimum runners to maintain | `1` |
| scaling.max_runners | Maximum runners allowed | `3` |
| scaling.desired_runners | Initial capacity; `null` lets the function pick | `null` |
| scaling.scale_out_threshold | Queued jobs that trigger scale-out | `3` |
| scaling.scale_in_threshold | Queued jobs below which to scale in | `1` |
| scaling.scale_out_step | Instances to add per scale-out | `1` |
| scaling.scale_in_step | Instances to remove per scale-in | `1` |
| scaling.scale_out_cooldown_duration | Minutes to wait after scale-out (min 4) | `4` |
| scaling.scale_in_cooldown_duration | Minutes to wait after scale-in | `5` |
| scaling.schedule_cron | NCRONTAB expression driving the timer trigger | `0 */1 * * * *` |
| storage.account_tier | Storage Account tier for autoscaler state | `Standard` |
| storage.account_replication_type | Replication strategy (LRS, GRS, RAGRS, ZRS) | `LRS` |
| storage.account_url | Explicit storage account URL (for private endpoints) | `""` |
| storage.use_rbac | Authenticate to storage with the managed identity instead of a connection string | `false` |
| application_insights_retention_in_days | Telemetry retention (30, 60, 90, 120, 180, 270, 365, 550, 730) | `30` |
| autoscaler_repo.url | Git repository holding the Function App code | `https://github.com/StackGuardian/sg-runner-autoscaler` |
| autoscaler_repo.branch | Branch to deploy from | `main` |

`override_names.runner_group_name` is not merely cosmetic here: it becomes the `SG_RUNNER_GROUP` app setting the function uses to query the queue. Leave it empty and the function has no runner group to poll.

The function code is not vendored in this repository. On apply, the template reads the tip commit of `autoscaler_repo.branch` with `git ls-remote`, clones it, zips it, and pushes it with `az functionapp deployment source config-zip`. Because the commit hash is a replace trigger, a new commit on that branch redeploys the code on the next apply — pin `autoscaler_repo.branch` to a tag or a fork if you want that frozen. The runner type is fixed to `external`; there is no `runner_type` input on the Azure side.

### Outputs

| Output | Description |
|--------|-------------|
| function_app_name | Name of the autoscaler Function App |
| function_app_id | Resource ID of the Function App |
| function_app_default_hostname | Default hostname of the Function App |
| function_app_identity_principal_id | Principal ID of the Function App's system-assigned identity |
| storage_account_name / storage_account_id | Storage Account holding autoscaler state |
| storage_container_name | Blob container holding the cooldown timestamps |
| application_insights_name | Application Insights instance |
| application_insights_instrumentation_key | Instrumentation key (sensitive) |
| application_insights_connection_string | Connection string (sensitive) |
| vmss_name / vmss_resource_group | The scale set under management |

---

## Template 5: Azure Runner (single VM)

Deploy one Linux VM as a StackGuardian runner instead of a scale set. Use this for a fixed-size footprint, for a pilot, or where a scale set is more machinery than the workload justifies. It takes the same required inputs as the VMSS template (`vm_image_id`, `runner_group_name`, `runner_group_token`, `storage_backend_identity_id`, `stackguardian.api_key`, `resource_group_name`) and the same `network`, `os_disk`, `firewall`, and `runner_startup_timeout` options.

Differences from Template 3:

- `vm_size` defaults to `Standard_D4s_v3`, but there is a single instance — no `scaling` and no `upgrade_policy`.
- `network.associate_public_ip` (default `false`) attaches a public IP directly to the VM's NIC. The VMSS template has no equivalent.
- Outputs are per-VM: `vm_id`, `vm_name`, `vm_private_ip`, `vm_public_ip`, `network_interface_id`, plus the same `network_security_group_id`, `vnet_id`, `subnet_id`, `ssh_private_key`, `ssh_public_key`, and `storage_backend_identity_id`.

The autoscaler template only manages a VM Scale Set, so this path is not autoscaled.

---

## Important Notes

**Deployment Order**: Templates must be deployed in sequence:

1. **Packer** — build the managed image first
2. **Runner Group** — create the runner group, resource group, and storage backend
3. **VM Scale Set** (or **Azure Runner**) — deploy instances using outputs from templates 1 and 2
4. **Autoscaler** — deploy the Function App using outputs from templates 2 and 3

**Output wiring between templates**:

| Producer | Output | Consumer | Input |
|----------|--------|----------|-------|
| packer | `image_id` | vmss / azure_runner | `vm_image_id` |
| runner_group | `runner_group_name` | vmss / azure_runner | `runner_group_name` |
| runner_group | `runner_group_name` | autoscaler | `override_names.runner_group_name` |
| runner_group | `runner_group_token` | vmss / azure_runner | `runner_group_token` |
| runner_group | `azure_resource_group_name` | vmss / autoscaler / azure_runner | `resource_group_name` |
| vmss | `vmss_name` | autoscaler | `vmss.name` |
| vmss | `vmss_resource_group_name` | autoscaler | `vmss.resource_group_name` |

**Managed identity model**: the runner VMs are assigned a **User-Assigned Managed Identity** (`storage_backend_identity_id`) so they can read and write the storage backend. That identity is an input you supply — the `runner_group` template does not emit one. On its Azure path, `runner_group` instead registers an Entra ID application plus service principal with an OIDC federated credential (issuer and audience are the StackGuardian API URI, subject `/orgs/<org>`) and grants that principal `Storage Blob Data Reader` on the storage account; that is how the *platform* reaches the backend, not how the *VMs* do. Create the User-Assigned Managed Identity yourself, grant it the blob data role you need on the storage account from `azure_storage_account_name`, and pass its resource ID in. The autoscaler Function App is separate again: it uses a **system-assigned** identity, created and role-assigned by that template.

**Resource group model**: Azure has no implicit container the way an AWS region does, so every template takes a `resource_group_name`. The simplest arrangement is to let `runner_group` create one (`create_azure_resource_group = true`) and pass its `azure_resource_group_name` output to all three Azure templates. The `packer` template can create its own separate resource group for images (`create_resource_group = true`), which keeps image lifecycle independent of the runner infrastructure.

**Azure CLI dependency**: three of these templates shell out to `az` during apply — Packer authenticates with `use_azure_cli_auth`, the autoscaler deploys the function zip with `az functionapp deployment source config-zip`, and image cleanup on destroy runs `az image delete`. The executing identity must be logged in (`az login`) *and* have the target subscription selected, not just have `ARM_*` provider credentials in the environment.

**Network Requirements**: Runner instances need outbound internet access to reach the StackGuardian API and download packages. Options include:

- An existing subnet with its own route to the internet (Azure Firewall, ExpressRoute, an existing NAT Gateway)
- A subnet created by the template with `network.create_network = true` and `network.create_network_infrastructure = true`, which provisions a NAT Gateway with a public IP. The template never attaches a NAT Gateway to a subnet it does not own, so this pair must be set together.
- An HTTP proxy via `network.proxy_url`

`network.service_endpoints` only applies to a subnet the template creates. When bringing your own subnet, configure the endpoints on it directly.

**API Key Security**: Use the `${secret::SECRET_NAME}` format to reference secrets stored in StackGuardian rather than hardcoding API keys. The whole `stackguardian` object is marked `sensitive` in every Azure template, so the key never appears in plan output; the templates call `nonsensitive()` on `org_name` and `api_uri` internally so those non-secret fields can still be used in resource names and URLs.

**Scaling Behavior**: The autoscaler Function App runs on a timer trigger driven by `scaling.schedule_cron` (every minute by default) and adjusts VMSS capacity based on job queue depth. Cooldown periods prevent rapid oscillation. `scaling.desired_capacity` on the VMSS template is only the initial size — it is ignored on subsequent applies so the autoscaler and Terraform do not fight over instance count.

---

## How Azure Differs from AWS

These are not cosmetic naming differences; they change how the stack behaves.

- **Rollout of image changes.** The AWS Auto Scaling Group performs a rolling `instance_refresh` when the launch template changes. The Azure VMSS defaults to `upgrade_mode = "Manual"`: pointing `vm_image_id` at a new image updates the scale set model, but running instances keep the old model until the autoscaler or an operator replaces them. Set `upgrade_policy.mode = "Rolling"` (with a health signal) to get behaviour comparable to the AWS instance refresh. Azure cannot change the upgrade mode of an existing scale set, so switching this value **replaces the VMSS and recreates every runner**.
- **What runs the autoscaler.** AWS uses a Lambda on an EventBridge Scheduler rate expression. Azure uses a Flex Consumption (`FC1`) Function App running Python 3.11, driven by an NCRONTAB timer trigger (`scaling.schedule_cron`). There is no `lambda_config` equivalent — runtime and version are fixed by the template.
- **Where the function code comes from.** Both platforms pull the autoscaler from `autoscaler_repo`. On Azure the deployment is a `git clone` plus `az functionapp deployment source config-zip` executed by a local provisioner, which is why `git`, `zip`, and `az` must be present wherever you run the apply.
- **Permissions.** AWS grants an IAM role with inline policies. Azure grants built-in roles to the Function App's system-assigned identity: `Virtual Machine Contributor` on the scale set, `Reader` and `Network Contributor` on the scale set's resource group, and `Storage Blob Data Contributor` (or `Storage Blob Data Owner` in RBAC mode) on the autoscaler storage account, plus queue and table data roles when `storage.use_rbac = true`. Creating these requires `Microsoft.Authorization/roleAssignments/write`.
- **Storage backend.** AWS uses an S3 bucket with a cross-account IAM role and an external ID. Azure uses a Storage Account with a container named `runner` and an OIDC federated credential on an Entra ID app registration. `s3_bucket_name` and `storage_backend_role_arn` are `null` on the Azure path; `azure_storage_account_name` and `azure_resource_group_name` take their place.
- **Naming.** Azure resource names are lowercased and underscores become hyphens, because several Azure resource types reject the `SG_RUNNER` style. The storage account name is truncated and given a random suffix to satisfy the 3–24 character globally-unique lowercase-alphanumeric rule.
- **Org name resolution.** Azure templates take the organization name from `stackguardian.org_name`, falling back to the `SG_ORG_ID` environment variable. There is no `override_names.org_name` input.

---

## Security Features

- Managed identities throughout — user-assigned for runner instances, system-assigned for the autoscaler Function App; no static cloud credentials on the VMs
- OIDC federated credentials for the StackGuardian connector instead of a long-lived client secret
- Built-in Azure roles scoped to the specific scale set, resource group, or storage account rather than subscription-wide grants
- Storage accounts enforce TLS 1.2 and disallow public blob access
- Network security groups default to deny, with SSH and any additional ports opened only on request
- Optional VNet service endpoints so runners reach Azure PaaS over the Azure backbone
- NAT Gateway support so runners get outbound access without public IPs
- Bring-your-own SSH key (`firewall.ssh_public_key`) so no private key is ever written to state; key generation is opt-in
- Automatic image cleanup on destroy, scoped to the image this deployment actually built
