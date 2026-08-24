# StackGuardian Private Runner Image Builder - Azure Module

Terraform module that builds a custom Azure managed image preloaded with the StackGuardian Private Runner agent, Terraform, and OpenTofu, using HashiCorp Packer driven from a `null_resource` `local-exec`.

## Overview

This module provisions an Azure managed image that the sibling `azure_runner` autoscaler module (or any VM/VMSS) can boot directly. Packer is invoked from Terraform, the build runs against either a temporary or an existing VNet/subnet, and the resulting image ID is parsed back out of the Packer manifest and exposed as a Terraform output. Optionally, the module can also create the destination resource group and clean up the image on `terraform destroy`.

### What Gets Created

- **`azurerm_resource_group`** (optional, count-gated by `create_resource_group`): destination resource group for the image.
- **`null_resource.packer_build`**: runs `scripts/build_image.sh`, which installs Packer, renders `image.pkr.hcl`, and triggers the build. Runs on the first apply, and again only when `packer_config.rebuild_image_token` changes.
- **`data.external.packer_image_id`**: parses `packer_manifest.log` to extract the resource ID of the freshly built managed image.
- **`terraform_data.image_id`**: records that image ID in state, so later plans read it from state instead of the build log.
- **`null_resource.image_cleanup`** (when `cleanup_images_on_destroy = true`): destroy-time hook that runs `scripts/cleanup_image.sh` to delete the image from Azure.

## Prerequisites

- An Azure subscription and credentials available to the runner (one of: `az login`, `ARM_*` service-principal env vars, or managed identity).
- Permission to create managed images in the target resource group (and to create the resource group itself, if `create_resource_group = true`).
- Outbound network access from the build VM to package mirrors (Ubuntu archive / RHEL repos, HashiCorp/OpenTofu releases). If the network is locked down, supply `network.proxy_url`.
- `sh`, `curl`, and `unzip` available on the machine running Terraform — `scripts/setup.sh` uses them to bootstrap Packer (default version `1.14.1`).

## Quick Start

### Step 1: Configure Azure credentials

```bash
az login
az account set --subscription "<your-subscription-id>"
```

### Step 2: Apply the module

```bash
terraform init
terraform plan
terraform apply
```

### Basic Configuration Example

```hcl
module "private_runner_image" {
  source = "./packer"

  resource_group_name   = "sg-runner-images-rg"
  create_resource_group = true
}
```

## Configuration

### Required Parameters

| Parameter | Description | Type |
|-----------|-------------|------|
| `resource_group_name` | Resource group where the image will be stored | `string` |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `azure_location` | Target Azure region for the build | `"westeurope"` |
| `create_resource_group` | Create the resource group as part of this deployment | `false` |
| `vm_size` | Packer build VM size (min 2 vCPU / 4GB RAM) | `"Standard_D2s_v3"` |
| `network.vnet_name` | Existing VNet to attach the build VM to | `""` (Packer creates temp networking) |
| `network.subnet_name` | Existing subnet inside the VNet above | `""` |
| `network.resource_group_name` | Resource group containing the existing VNet | `""` |
| `network.proxy_url` | HTTP proxy URL forwarded to the build VM | `""` |
| `os.publisher` | Image publisher — `Canonical` or `RedHat` | `"Canonical"` |
| `os.offer` | Marketplace image offer | `"0001-com-ubuntu-server-jammy"` |
| `os.sku` | Marketplace image SKU | `"22_04-lts-gen2"` |
| `os.version` | Marketplace image version | `"latest"` |
| `os.update_os_before_install` | Run full OS update before installing the agent | `true` |
| `os.user_script` | Extra shell script executed after agent install | `""` |
| `packer_config.version` | Packer version bootstrapped by `scripts/setup.sh` | `"1.14.1"` |
| `packer_config.rebuild_image_token` | Change to any new value to build a fresh image once | `""` |
| `packer_config.cleanup_images_on_destroy` | Delete the image on `terraform destroy` | `true` |
| `image_name_prefix` | Prefix for the generated image name | `"sg-runner"` |
| `terraform.primary_version` | Default Terraform version pre-installed | `""` |
| `terraform.additional_versions` | Extra Terraform versions to install | `[]` |
| `opentofu.primary_version` | Default OpenTofu version pre-installed | `""` |
| `opentofu.additional_versions` | Extra OpenTofu versions to install | `[]` |

### When Packer Runs

Building an image takes several minutes, so this module builds **once per state** and
then reuses what it built:

| Situation | Result |
|-----------|--------|
| First apply | Packer builds the image, and its ID is recorded in state |
| Every plan/apply after that | No build, no diff — the image ID comes from state |
| `rebuild_image_token` changed to a new value | Packer builds a new image, once |
| State destroyed and re-applied | Packer builds again |

```hcl
# Force one fresh build (e.g. to pick up new Terraform/OpenTofu versions)
packer_config = {
  version             = "1.14.1"
  rebuild_image_token = "2026-07-30-tofu-1.11"
}
```

The token is deliberately a free-form string rather than an on/off flag: bump it to
rebuild, then leave it alone. A boolean would build again the moment you unset it.

The recorded image ID lives in `terraform_data.image_id`, not in `packer_manifest.log`,
so plans stay stable on a fresh checkout, on a CI runner, or after the log is deleted.
Because the ID no longer changes on every apply, the runner VM/VMSS is no longer
replaced on every apply either.

> **Note:** `packer_config.cleanup_images_on_destroy` (default `true`) only ever
> touches the image this deployment built — on destroy, and on the rebuild that
> supersedes it. Images belonging to other deployments are never deleted, since the
> module never adopts an image it did not build.

### Configuration Examples

#### Basic Configuration

```hcl
module "private_runner_image" {
  source = "./packer"

  resource_group_name   = "sg-runner-images-rg"
  create_resource_group = true
}
```

#### Advanced Configuration

```hcl
module "private_runner_image" {
  source = "./packer"

  azure_location        = "northeurope"
  resource_group_name   = "sg-runner-images-rg"
  create_resource_group = false
  vm_size               = "Standard_D4s_v3"
  image_name_prefix     = "sg-runner-prod"

  network = {
    vnet_name           = "shared-vnet"
    subnet_name         = "build-subnet"
    resource_group_name = "shared-network-rg"
    proxy_url           = "http://proxy.internal:8080"
  }

  os = {
    publisher                = "RedHat"
    offer                    = "RHEL"
    sku                      = "9-lvm-gen2"
    version                  = "latest"
    update_os_before_install = true
    user_script              = file("${path.module}/hardening.sh")
  }

  packer_config = {
    version                   = "1.14.1"
    rebuild_image_token       = "2026-07-30-tofu-1.11"
    cleanup_images_on_destroy = true
  }

  terraform = {
    primary_version     = "1.6.6"
    additional_versions = ["1.5.7"]
  }

  opentofu = {
    primary_version     = "1.8.0"
    additional_versions = ["1.7.3"]
  }
}
```

## Usage

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

The first `apply` runs the Packer build; every `apply` after that reuses the image ID recorded in state and does nothing. After changing `terraform`/`opentofu`/`os`/`network` settings, set `packer_config.rebuild_image_token` to a new value to build once with the new configuration (see [When Packer Runs](#when-packer-runs)).

### Cleanup

```bash
terraform destroy
```

When `packer_config.cleanup_images_on_destroy = true` (default), the destroy provisioner runs `scripts/cleanup_image.sh` and deletes the managed image from Azure. If disabled, the image will remain in the resource group and must be deleted manually (see `cleanup_commands` output).

## Architecture

### Resource Organization

- `image.pkr.hcl` — Packer template (azure-arm builder + provisioners).
- `main.tf` — Terraform resources (RG, build, manifest parsing, recorded image ID, cleanup).
- `locals.tf` — derived values (OS family, SSH username, image name, RG selection).
- `variables.tf` — input variables.
- `outputs.tf` — exported image metadata and cleanup commands.
- `provider.tf` — provider requirements.
- `scripts/setup.sh` — installs Packer at `packer_config.version`.
- `scripts/build_image.sh` — orchestrates the build and writes `packer_manifest.log`.
- `scripts/cleanup_image.sh` — destroy-time image deletion.

### Resource Naming Convention

Image name follows: `{image_name_prefix}-{os_family}-{os.sku}` where `os_family` is `ubuntu` for `Canonical` and `rhel` for `RedHat`. A timestamp suffix is appended by Packer at build time.

## Troubleshooting

### Common Issues

1. **`az` CLI / Azure auth not available**
   - Run `az login`, or export `ARM_CLIENT_ID` / `ARM_CLIENT_SECRET` / `ARM_TENANT_ID` / `ARM_SUBSCRIPTION_ID` before `terraform apply`.

2. **Packer install fails in `scripts/setup.sh`**
   - Confirm outbound HTTPS to `releases.hashicorp.com`. Behind a proxy, set `HTTPS_PROXY` in the runner environment as well as `network.proxy_url`.

3. **`image_id` output is blank**
   - The build failed before producing an artifact, so nothing was recorded in state. Inspect the Terraform `local-exec` output and re-run the script manually with the same env vars to surface the Packer error, then change `packer_config.rebuild_image_token` to retry the build.
   - A missing or deleted `packer_manifest.log` does **not** blank the output: the ID is read from `terraform_data.image_id` in state.

4. **Cleanup script can't find the image**
   - The image was already deleted manually or by a prior destroy. The script exits non-fatally; you can ignore it.

5. **Existing VNet/Subnet not used**
   - All three of `network.vnet_name`, `network.subnet_name`, and `network.resource_group_name` must be set; otherwise Packer falls back to creating temporary networking.

### Debugging Commands

```bash
# Tail the latest build output
tail -f packer_manifest.log

# Re-run the build script manually
sh scripts/build_image.sh

# Inspect the produced image
az image show --ids "$(terraform output -raw image_id)"

# List all images produced by this prefix
az image list --resource-group "$(terraform output -raw resource_group_name)" \
  --query "[?starts_with(name, 'sg-runner')].{name:name, id:id}" -o table
```

## Outputs

| Output | Description |
|--------|-------------|
| `image_id` | Resource ID of the created Azure managed image |
| `image_info` | Comprehensive image metadata (id, location, RG, OS family/SKU, image name, prefix, cleanup settings) |
| `resource_group_name` | Resource group where the image is stored |
| `cleanup_commands` | Azure CLI commands to inspect or manually delete the image |

## Security Considerations

- Image stays inside the customer's subscription and resource group — nothing is published to a shared gallery.
- No inbound ports are exposed; Packer uses ephemeral SSH credentials over the (temporary or supplied) subnet.
- HTTP proxy support via `network.proxy_url` for restricted egress environments.
- `os.user_script` allows custom hardening, CA cert injection, or extra tooling without forking the module.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.4.0 (`terraform_data`) |
| azurerm | >= 3.0 |
| null | >= 3.0 |
| external | >= 2.0 |

## Next Steps

Pass `module.private_runner_image.image_id` into the sibling `azure_runner` module (or your own VMSS) to boot StackGuardian private runners from the freshly built image.

## Support

- StackGuardian docs: <https://docs.stackguardian.io>
- Module source / issues: this repository
