# StackGuardian Private Runner — Azure Image Build

Builds the runner managed image and nothing else. No runner group, no connector,
no VM — just the image, so you can bake it once and point other deployments at
the resulting `image_id`.

> For a full working runner in one apply, use
> [examples/azure/quickstart](../quickstart/) instead — it wires this same module
> together with the runner group and a VM runner.

## What Gets Built

```
tofu apply
    |
    v
[Resource group]  azurerm_resource_group   (unless create_resource_group = false)
    |
    v
[Packer build]  null_resource.packer_build
    |   temporary VM + temporary VNet, both removed when the build ends
    |   installs: Docker, jq, cron, unzip, sg-runner
    |   optional: Terraform and/or OpenTofu at the versions you name
    |   generalizes the VM and captures it
    v
[Record the image ID]  terraform_data.image_id  ->  output image_id
```

Only the resource group and the managed image persist. The build VM, its disk and
its temporary networking are created and destroyed by Packer within the run.

## Prerequisites

| Requirement | Notes |
|-------------|-------|
| **OpenTofu >= 1.4** (or Terraform >= 1.4) | The module uses `terraform_data` |
| **Azure CLI, logged in** | The build and the cleanup script shell out to `az` |
| **Azure credentials** | Via `az login` or `ARM_*` environment variables |
| **Contributor** on the target scope | Resource groups, images, VMs, disks, temporary networking |
| `sh`, `curl`, `unzip` | Used to bootstrap Packer at `packer_config.version` |

Packer itself is downloaded automatically — you do not need it installed. Unlike
the AWS build, you do **not** need to bring a network: Packer makes its own.

## Quick Start

```bash
cp terraform.tfvars.tpl terraform.tfvars
$EDITOR terraform.tfvars     # set resource_group_name
tofu init
tofu apply
tofu output image_id
```

The build takes several minutes. Once it finishes, the image ID is recorded in
state and every later plan is a no-op — see [Rebuilding](#rebuilding).

## Configuration

### Required

| Variable | Type | Description |
|----------|------|-------------|
| `resource_group_name` | `string` | Resource group the image is stored in |

### Commonly Adjusted

| Variable | Default | Description |
|----------|---------|-------------|
| `azure_location` | `westeurope` | A managed image is regional — build it where you intend to create runners |
| `vm_size` | `Standard_D2s_v3` | Build VM size |
| `create_resource_group` | `true` | Set `false` to build into a resource group that already exists |
| `os.publisher` | `Canonical` | `Canonical` or `RedHat` |
| `os.offer` / `os.sku` | Ubuntu 22.04 LTS gen2 | Marketplace offer and SKU |
| `image_name_prefix` | `sg-runner` | Prefix of the generated image name |
| `terraform.primary_version` | `""` | Installed as `/bin/terraform` |
| `opentofu.primary_version` | `""` | Installed as `/bin/tofu` |
| `sg_runner.pre_release` | `false` | Bake the newest sg-runner pre-release instead of latest stable |

Everything under `os`, `terraform`, `opentofu` and `sg_runner` is baked in at
build time, so changing any of them has **no effect on an existing image** until
you trigger a rebuild.

Confirm your `os` combination exists in the target region before applying:

```bash
az vm image list --location westeurope --publisher Canonical --all -o table
```

### Building Inside an Existing VNet

By default Packer creates a throwaway VNet for the build and removes it
afterwards. Set `network` when the build must run inside your own:

```hcl
network = {
  vnet_name           = "my-vnet"
  subnet_name         = "build-subnet"
  resource_group_name = "my-network-rg"
  proxy_url           = ""
}
```

> With `network` set, Packer connects to the build VM over its **private IP** and
> assigns no public one, so wherever you run OpenTofu needs a route into that
> subnet. Leave it empty unless you have one. Either way the subnet needs
> outbound internet access.

## Rebuilding

The image is built **once per state**. Later plans reuse the recorded ID, so the
image stays stable and downstream deployments are not disturbed.

| Situation | Result |
|-----------|--------|
| First apply | Packer builds; the image ID is recorded in state |
| Every plan/apply after that | No build, no diff |
| `packer_config.rebuild_image_token` changed | Packer builds a new image, once |
| State destroyed and re-applied | Packer builds again |

```hcl
packer_config = {
  rebuild_image_token = "2026-08-25-tofu-1.11"   # any new value
}
```

The token is a free-form string rather than a boolean on purpose: bump it to
rebuild, then leave it alone. A boolean would rebuild again the moment you unset it.

## Outputs

| Output | Description |
|--------|-------------|
| `image_id` | The built managed image, recorded in state — feed this to `azure/azure_runner` or `azure/vmss` |
| `image_info` | Location, resource group, OS, image name and cleanup settings |
| `resource_group_name` | Resource group holding the image |
| `cleanup_commands` | Ready-to-run `az` commands for inspecting or removing the image by hand |

## Destroying

```bash
tofu destroy
```

With `packer_config.cleanup_images_on_destroy` (default `true`) this deletes the
image this deployment built. Images from other deployments are never touched. Set
it to `false` to keep the image after tearing down the state.

> Deleting an image that other deployments still reference will break their next
> VM creation. A running VM keeps working, but it can no longer be recreated.
> Check `image_id` before destroying.

## Troubleshooting

| Symptom | Likely cause |
|---------|--------------|
| Packer fails immediately | `az login` not done, or missing permissions on the target scope |
| SKU not available in region | Verify with `az vm image list --location <region> --publisher <publisher> --all` |
| Build hangs connecting to the VM | `network` points at a subnet you have no route into — leave it empty to use Packer's own networking |
| `No image recorded` on output | The build produced no image — check `../../../azure/packer/packer_manifest.log` |
| Packer never re-runs | Working as designed; bump `rebuild_image_token` |
| Image is in the wrong region | `azure_location` — an image can only create VMs in its own region |

To force a rebuild without touching variables:

```bash
tofu apply -replace=module.packer.null_resource.packer_build
```

## Notes

- The provisioning script is shared with the AWS build:
  [`packer/scripts/setup.sh`](../../../packer/scripts/setup.sh). A fix there lands
  on both clouds.
- No backend is configured. The recorded image ID lives in local state, so keep it
  if you want later plans to skip the build.
