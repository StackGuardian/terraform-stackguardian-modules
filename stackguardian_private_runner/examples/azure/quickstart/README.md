# StackGuardian Private Runner - Azure Quickstart

Zero to a registered, running Private Runner on Azure in a single `apply`.

This example wires the three building-block modules together into one root module,
so you configure a handful of values once instead of running three deployments and
hand-copying outputs between them.

> Deploying a **single runner** on a newly created VNet with a public IP. For an
> autoscaled fleet, use the `azure/vmss` and `azure/autoscaler` modules directly -
> see the [top-level README](../../../README.md).

For a no-Packer variant that installs everything at first boot, see
[`../standalone-vm`](../standalone-vm).

## Contents

- [What Gets Deployed](#what-gets-deployed)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [How the Image Lifecycle Works](#how-the-image-lifecycle-works)
- [Networking](#networking)
- [The Storage Backend Identity](#the-storage-backend-identity)
- [Outputs](#outputs)
- [Accessing the Runner](#accessing-the-runner)
- [Day-2 Operations](#day-2-operations)
- [Destroying](#destroying)
- [Troubleshooting](#troubleshooting)
- [Limitations](#limitations)

## What Gets Deployed

```
                     ┌──────────────────────────────┐
  module.runner_group│  StackGuardian control plane │
  ──────────────────►│  • runner group              │
        │            │  • AZURE_OIDC connector      │
        │            └──────────────────────────────┘
        │            ┌──────────────────────────────┐
        └───────────►│  Azure (storage backend)     │
                     │  • resource group            │
                     │  • storage account + CORS    │
                     │  • "runner" blob container   │
                     │  • AAD app + service         │
                     │    principal, federated to   │
                     │    the SG platform via OIDC  │
                     └──────────────────────────────┘
                                    │
                                    │ azure_resource_group_name
                                    │ azure_storage_account_name
                                    │ runner_group_name
                                    │ runner_group_token
                                    ▼
  module.packer      ┌──────────────────────────────┐
  ──────────────────►│  Packer build (first apply)  │
                     │  • temp build VM + temp      │
                     │    networking (auto-removed) │
                     │  • managed image: Docker,    │
                     │    jq, cron, sg-runner, and  │
                     │    optional Terraform/Tofu   │
                     └──────────────────────────────┘
                                    │
                                    │ image_id
                                    ▼
  (root module)      ┌──────────────────────────────┐
  ──────────────────►│  User-Assigned Managed       │
                     │  Identity + "Storage Blob    │
                     │  Data Contributor" on the    │
                     │  storage account             │
                     └──────────────────────────────┘
                                    │
                                    │ identity id
                                    ▼
  module.azure_runner
                     ┌──────────────────────────────┐
                     │  Runner VM                   │
                     │  • VNet + subnet             │
                     │  • NSG (all egress, no       │
                     │    ingress unless SSH is     │
                     │    configured)               │
                     │  • static public IP + NIC    │
                     │  • the managed identity      │
                     │    attached to the VM        │
                     └──────────────────────────────┘
```

Everything lands in **one resource group**, created by the runner group module and
reused by the other two, so a single `destroy` removes the whole deployment.

The runner registers itself with the StackGuardian platform on first boot using the
runner group token, then starts polling for work.

## Prerequisites

| Requirement | Notes |
|-------------|-------|
| **OpenTofu >= 1.4** (or Terraform >= 1.4) | The packer module uses `terraform_data` |
| **Packer** | Downloaded automatically by the build script at the configured version |
| **Azure CLI, logged in** | The Packer build and the image cleanup script shell out to `az` |
| **Azure credentials** | Via `az login` or `ARM_*` environment variables |
| **StackGuardian API key** | Org-scoped key with permission to create runner groups and connectors |
| **An SSH public key** | Password auth is always disabled on the VM |

### Azure Permissions

The identity running this needs, at minimum:

- **Contributor** on the subscription or target scope - resource groups, storage
  accounts, images, VMs, VNets, NSGs, public IPs, managed identities
- **User Access Administrator** (or equivalent) for the two role assignments. If you
  do not have it, set `create_role_assignments = false` and create them out of band -
  see [The Storage Backend Identity](#the-storage-backend-identity)
- **Azure AD**: permission to create an application and service principal, for the
  OIDC connector the runner group module registers

## Quick Start

**1. Copy the template and fill it in**

```bash
cp terraform.tfvars.tpl terraform.tfvars
$EDITOR terraform.tfvars
```

At minimum you must set `stackguardian.api_key` and `stackguardian.org_name`. Set
`firewall.ssh_public_key` too unless you want a generated key sitting in state.

**2. Initialize**

```bash
tofu init
```

**3. Review the plan**

```bash
tofu plan -out=tofuplan
```

**4. Apply**

```bash
tofu apply tofuplan
```

The first apply builds the managed image, which dominates the runtime - expect
several minutes before the runner VM itself is created. Later applies skip the build
entirely (see [image lifecycle](#how-the-image-lifecycle-works)).

**5. Confirm the runner came up**

```bash
tofu output runner_group_url
```

Open that URL; the runner should appear as active in the runner group within a
minute or two of the VM booting.

## Configuration

### Required

| Variable | Type | Description |
|----------|------|-------------|
| `stackguardian.api_key` | `string` | StackGuardian API key (sensitive) |
| `stackguardian.org_name` | `string` | StackGuardian organization name |

Everything else has a default. `firewall.ssh_public_key` is not formally required
only because `firewall.generate_ssh_key` defaults to `true`.

### Commonly Adjusted

| Variable | Default | Description |
|----------|---------|-------------|
| `azure_location` | `westeurope` | Region for all Azure resources |
| `stackguardian.api_uri` | `https://api.app.stackguardian.io` | Platform endpoint - see note below |
| `azure_resource_group_name` | `""` | Name of the shared resource group; derived from the prefix when empty |
| `firewall.ssh_public_key` | `""` | Your SSH public key; avoids a generated key in state |
| `firewall.ssh_access_rules` | `{}` | CIDRs allowed to reach port 22; nothing is open by default |
| `runner_vm_size` | `Standard_D4s_v3` | Runner VM size |
| `packer_vm_size` | `Standard_D2s_v3` | Build VM size |
| `max_runners` | `3` | Max runners in the runner group |
| `override_names.global_prefix` | `SG_RUNNER` | Prefix for created resource names |
| `runner_startup_timeout` | `300` | Seconds to wait for Docker before self-shutdown |
| `create_role_assignments` | `true` | Set `false` when you cannot write role assignments |

> **`api_uri` must be one of three known values.** The runner group module maps the
> API host to its matching web-console host to build the console URL and the storage
> account's CORS origin. Supported values are `https://api.app.stackguardian.io`
> (EU1), `https://api.us.stackguardian.io` (US1), and
> `https://testapi.qa.stackguardian.io` (QA). Any other value fails validation.

### Image Contents

| Variable | Default | Description |
|----------|---------|-------------|
| `os.publisher` | `Canonical` | `Canonical` or `RedHat` |
| `os.offer` / `os.sku` | Ubuntu 22.04 LTS gen2 | Marketplace offer and SKU |
| `os.update_os_before_install` | `true` | Patch the OS before installing |
| `os.user_script` | `""` | Extra shell run after standard setup |
| `terraform.primary_version` | `""` | Installed as `/bin/terraform` |
| `terraform.additional_versions` | `[]` | Installed as `/bin/terraform<version>` |
| `opentofu.primary_version` | `""` | Installed as `/bin/tofu` |
| `opentofu.additional_versions` | `[]` | Installed as `/bin/tofu<version>` |
| `image_name_prefix` | `sg-runner` | Prefix of the generated image name |

Every one of these is baked into the image at build time, so changing any of them
on an existing deployment has **no effect until you trigger a rebuild**.

Confirm your `os` combination exists in the target region before applying:

```bash
az vm image list --location westeurope --publisher Canonical --all -o table
```

### Full Variable Reference

See [`variables.tf`](variables.tf) - every variable is documented there, and
[`terraform.tfvars.tpl`](terraform.tfvars.tpl) shows each one with its default.

## How the Image Lifecycle Works

Building an image takes minutes, so the packer module builds **once per state** and
reuses what it built:

| Situation | Result |
|-----------|--------|
| First apply | Packer builds the image; its resource ID is recorded in state |
| Every plan/apply after that | No build, no diff - the ID comes from state |
| `packer_config.rebuild_image_token` changed | Packer builds a new image, once |
| State destroyed and re-applied | Packer builds again |

To force a fresh build - after changing the OS, `user_script`, or tool versions:

```hcl
packer_config = {
  version             = "1.14.1"
  rebuild_image_token = "2026-08-24-tofu-1.11"   # any new value
}
```

The token is a free-form string rather than a boolean on purpose: bump it to
rebuild, then leave it alone. A boolean would rebuild again the moment you unset it.

Because the image ID is stable across applies, **the runner VM is not replaced on
every apply**. A rebuild does replace it, since the VM's source image changes.

> `packer_config.cleanup_images_on_destroy` (default `true`) only ever touches the
> image this deployment built - on destroy, and on the rebuild that supersedes it.
> Images from other deployments are never deleted.

## Networking

This example creates a **new VNet and subnet** for the runner and attaches a static
public IP, relying on Azure's default outbound route for internet access. Packer, by
default, builds on its own throwaway VNet that it removes when the build finishes.

The runner's NSG allows **all egress** and **no ingress**. SSH is opened only if you
set `firewall.ssh_access_rules`.

### Service Endpoints

If you lock the storage account down to specific subnets, or you want the runner's
blob traffic to stay on the Azure backbone rather than crossing the public internet:

```hcl
network = {
  service_endpoints = ["Microsoft.Storage"]
}
```

These apply to the subnet this example creates. The default is `[]`, which is fine
for the default storage account configuration (`public_network_access_enabled = true`
with no network rules).

### Building Inside an Existing VNet

If the build VM must sit in your network - a proxy-only environment, or a policy
that forbids ad-hoc VNets:

```hcl
packer_network = {
  vnet_name           = "my-vnet"
  subnet_name         = "build-subnet"
  resource_group_name = "my-network-rg"
  proxy_url           = "http://proxy.example.com:8080"
}
```

## The Storage Backend Identity

The runner authenticates to the storage account with a **User-Assigned Managed
Identity**. The `runner_group` module does not create one - it registers an AAD
application and service principal for the *platform's* OIDC connector, which is a
different principal with a different purpose. So this root module creates the
identity itself and grants it `Storage Blob Data Contributor` on the storage
account, then passes its resource ID to `azure/azure_runner`.

Two role assignments exist in this deployment:

| Principal | Role | Purpose |
|-----------|------|---------|
| Connector service principal (from `runner_group`) | `Storage Blob Data Reader` | Lets the SG platform read job state |
| Runner managed identity (from this root module) | `Storage Blob Data Contributor` | Lets the runner read and write job state |

Both are gated on `create_role_assignments`. If the identity running OpenTofu lacks
`Microsoft.Authorization/roleAssignments/write`, set it to `false` and create both by
hand:

```bash
az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee-object-id "$(tofu output -raw storage_backend_identity_principal_id)" \
  --assignee-principal-type ServicePrincipal \
  --scope "$(az storage account show -n "$(tofu output -raw storage_account_name)" \
             -g "$(tofu output -raw resource_group_name)" --query id -o tsv)"
```

Azure RBAC propagation is eventually consistent. A runner that boots seconds after
the assignment is created may see access errors on its first job; they clear on
their own.

## Outputs

| Output | Description |
|--------|-------------|
| `runner_group_name` | Name of the created runner group |
| `runner_group_url` | Direct link to the runner group in the web console |
| `connector_name` | Name of the created connector |
| `resource_group_name` | Resource group holding everything |
| `storage_account_name` | Storage account backing the runner group |
| `storage_backend_identity_id` | Resource ID of the runner's managed identity |
| `storage_backend_identity_principal_id` | Principal ID, for out-of-band role assignment |
| `image_id` | Managed image built by Packer and recorded in state |
| `vm_id` / `vm_name` | Runner VM resource ID and name |
| `vm_public_ip` / `vm_private_ip` | Runner IPs |
| `network_security_group_id` | Runner NSG ID |
| `ssh_command` | Ready-to-paste SSH command |
| `ssh_private_key` | Generated private key (sensitive), when `generate_ssh_key` is true |

The runner group token is deliberately **not** exposed as a root output. It is
passed module-to-module in memory and marked sensitive.

## Accessing the Runner

SSH requires opening the NSG first:

```hcl
firewall = {
  ssh_public_key   = "ssh-ed25519 AAAA..."
  ssh_access_rules = { "my-ip" = "203.0.113.10/32" }
}
```

Then:

```bash
$(tofu output -raw ssh_command)
```

If you let the module generate the key:

```bash
tofu output -raw ssh_private_key > runner_key.pem
chmod 600 runner_key.pem
ssh -i runner_key.pem "$(tofu output -raw ssh_command | cut -d' ' -f2)"
```

Without SSH, use the serial console or run-command from the Azure portal.

Useful checks once you are on the box:

```bash
sudo tail -f /var/log/sg_runner_startup.log   # registration + startup
sudo tail -f /var/log/cloud-init-output.log   # full custom_data run
docker ps                                     # job containers
systemctl status docker                       # runner depends on this
```

> `sg-runner` is a shell script at `/usr/bin/sg-runner`, not a systemd service.
> It is invoked once from `custom_data` as `sg-runner register ...`, so there is no
> `systemctl status sg-runner` or `journalctl -u sg-runner` to check.

## Day-2 Operations

**Update the sg-runner binary in place** (no rebuild, no OpenTofu):

```bash
sudo sg-runner-update
```

**Change what is baked into the image** - edit `os`, `terraform`, or `opentofu`,
then bump `packer_config.rebuild_image_token` and apply. This replaces the image
*and* the runner VM.

**Resize the runner** - change `runner_vm_size` and apply. No rebuild needed.

## Destroying

```bash
tofu destroy
```

This deletes the managed image (unless `cleanup_images_on_destroy` is disabled),
removes the runner group and connector from StackGuardian, and tears down the Azure
resources including the resource group.

> The storage account is deleted along with the resource group, **and its contents
> with it** - including the Terraform state of every job the runner executed. Unlike
> the AWS example, there is no `force_destroy` gate here. Copy anything you need out
> first.

## Troubleshooting

| Symptom | Likely cause |
|---------|--------------|
| `service_endpoints is not expected here` | azurerm resolved to 5.x; the modules need 4.x. This root module pins `~> 4.0` - do not loosen it |
| Plan fails validating `api_uri` | `stackguardian.api_uri` is not one of the three supported values |
| Plan fails validating `firewall` | Neither `ssh_public_key` nor `generate_ssh_key` is set |
| Packer fails immediately | `az login` not done, no outbound path from the build subnet, or missing permissions |
| `No image recorded` on output | The build produced no image ID - check `../../../azure/packer/packer_manifest.log` |
| Packer never re-runs | Working as designed; bump `rebuild_image_token` |
| `AuthorizationFailed` creating role assignments | Set `create_role_assignments = false` and create them out of band |
| Runner shuts itself down after boot | Docker did not start within `runner_startup_timeout` - `custom_data` calls `shutdown -h now` on timeout |
| Runner never appears in the console | Token or org name wrong; check `/var/log/sg_runner_startup.log` |
| Runner registers but jobs fail on state access | Role assignment missing or still propagating |
| SKU not available in region | Verify with `az vm image list --location <region> --publisher <publisher> --all` |

To force a rebuild without touching variables:

```bash
tofu apply -replace=module.packer.null_resource.packer_build
```

[`../standalone-vm/troubleshooting.md`](../standalone-vm/troubleshooting.md) covers a
separate failure mode - the ECS agent terminally exiting after a successful
registration because of a stale container-instance ARN. It applies to any private
runner, including this one.

## Limitations

This example trades flexibility for a short path to a working runner:

- **Public IP only.** `create_network_infrastructure` (NAT gateway), `proxy_url`,
  and attaching to an existing VNet/subnet are supported by `azure/azure_runner` but
  are not exposed here. Use the module directly when you need a private subnet, NAT
  gateway, or proxy.
- **Single runner.** No autoscaling; `max_runners` caps the runner group, not the
  VM count.
- **azurerm pinned to 4.x.** The `azure/*` modules use `azurerm_subnet.service_endpoints`,
  removed in azurerm 5.
- **Local state.** No backend is configured. Add one before using this for anything
  you intend to keep.
- **Creates a new runner group.** It does not attach to an existing one.
