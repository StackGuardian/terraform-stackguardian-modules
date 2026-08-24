# StackGuardian Private Runner Image Builder - Azure Template

Deploy this template on the StackGuardian platform to build a custom Azure managed image preloaded with the StackGuardian Private Runner agent, ready to be consumed by the Azure autoscaler.

## Overview

This template produces a reusable Azure managed image so your private runners boot fast with the agent, Terraform, and OpenTofu already installed. The image is built by HashiCorp Packer in your own Azure subscription, lands in a resource group you control, and is automatically removed when the workflow is destroyed. It is built on the first deployment only and reused on every run after that, so repeated runs cost no build time.

### What This Template Creates

- **Azure Managed Image** — your custom Private Runner image, tagged with OS family and timestamp. Built once, then recorded in state and reused.
- **Resource Group** *(optional)* — created for you when `Create Resource Group` is enabled; otherwise the existing one is reused.
- **Automatic cleanup hook** — deletes the image from Azure when the workflow is destroyed (can be disabled).

## Prerequisites

- Azure credentials configured on the StackGuardian runner (via `az login`, service principal env vars, or managed identity).
- Permission in the target subscription to create managed images (and the resource group, if you let the template create it).
- Outbound network access from Azure to package mirrors during the build, or an HTTP proxy reachable from the build VNet.

## Template Parameters

### Required Parameters

| Parameter | Description | Type |
|-----------|-------------|------|
| `resource_group_name` | The name of the resource group where the image will be stored | `string` |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `azure_location` | The target Azure region to build the Private Runner image | `westeurope` |
| `create_resource_group` | Create the resource group as part of this deployment. If disabled, it must already exist. | `false` |
| `vm_size` | The Azure VM size used by Packer during the build (min 2 vCPU, 4GB RAM recommended) | `Standard_D2s_v3` |
| `network.vnet_name` | Name of an existing virtual network to use for the build VM | `""` |
| `network.subnet_name` | Name of an existing subnet inside the VNet above | `""` |
| `network.resource_group_name` | Resource group containing the existing VNet (if different from the image resource group) | `""` |
| `network.proxy_url` | HTTP proxy URL forwarded to the build VM during image creation | `""` |
| `os.publisher` | Image publisher: Canonical (Ubuntu) or RedHat (RHEL) | `Canonical` |
| `os.offer` | Marketplace image offer | `0001-com-ubuntu-server-jammy` |
| `os.sku` | Marketplace image SKU | `22_04-lts-gen2` |
| `os.version` | Marketplace image version (use `latest` to always pull the newest) | `latest` |
| `os.update_os_before_install` | Run a full OS package update before installing the runner agent | `true` |
| `os.user_script` | Optional shell script run on the build VM after the runner agent is installed | `""` |
| `packer_config.version` | Packer version installed by the build script | `1.14.1` |
| `packer_config.rebuild_image_token` | Change to any new value to build a fresh image once; leaving it unchanged never rebuilds | `""` |
| `packer_config.cleanup_images_on_destroy` | Delete the managed image when the workflow is destroyed | `true` |
| `image_name_prefix` | Prefix used for the generated image name | `sg-runner` |
| `terraform.primary_version` | Default Terraform version available on the runner (leave empty to skip) | `""` |
| `terraform.additional_versions` | Extra Terraform versions to install alongside the primary version | `[]` |
| `opentofu.primary_version` | Default OpenTofu version available on the runner (leave empty to skip) | `""` |
| `opentofu.additional_versions` | Extra OpenTofu versions to install alongside the primary version | `[]` |

## Important Notes

**Image Reuse**: The image is built on the first deployment only. Its resource ID is recorded in state and reused on every run after that, so repeated runs cost no build time and the runner keeps the same image. To build a fresh image — after changing the OS, the user script, or the Terraform/OpenTofu versions — set *Rebuild Image Token* to any new value. Leaving the token unchanged never rebuilds.

**Cleanup on destroy**: When `cleanup_images_on_destroy` is left at its default (`true`), destroying the workflow deletes the image this deployment built, and a rebuild deletes the image it supersedes. Images built by other deployments are never touched. Disable it only if you need the image to survive workflow teardown — orphaned images will accumulate in the resource group otherwise.

**Existing VNet usage**: To pin the build VM to your own network, fill in **all three** of `network.vnet_name`, `network.subnet_name`, and `network.resource_group_name`. If any one is left blank, Packer falls back to creating temporary networking for the build.

**Supported OS families**: Only `Canonical` (Ubuntu) and `RedHat` (RHEL) are validated. The runner agent and tooling installers assume one of these two families.

## Outputs

| Output | Description |
|--------|-------------|
| `image_id` | Resource ID of the Azure managed image built by this deployment and recorded in state — pass this to the Azure runner template |
| `image_info` | Image metadata: ID, location, resource group, OS family/SKU, image name, name prefix, cleanup settings |
| `resource_group_name` | Resource group where the image is stored |
| `cleanup_commands` | Ready-made Azure CLI commands for manual image cleanup |

## Security Features

- Image stays inside your Azure subscription and resource group — nothing is published to a shared gallery.
- No inbound ports are exposed during the build; Packer uses ephemeral SSH over your subnet (or a temporary one).
- HTTP proxy support via `network.proxy_url` for restricted-egress environments.
- `os.user_script` lets you inject custom hardening, CA certificates, or extra tooling without modifying the template.
