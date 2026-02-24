# StackGuardian Private Runner - Packer Image Builder (Azure)

Build custom Azure Managed Images for StackGuardian Private Runner deployments with pre-installed dependencies and configurable tooling.

## Overview

This Terraform module automates the creation of custom Azure Managed Images using HashiCorp Packer. The resulting image includes Docker, Terraform, OpenTofu, and StackGuardian runner components, providing an optimized base image for Private Runner deployments.

### What Gets Created

- **Azure Managed Image**: Pre-configured image with all dependencies
- **Packer Build VM**: Temporary VM used during the build process (automatically terminated)
- **Resource Group** (optional): When `create_resource_group = true`

### What Gets Installed on the Image

- Docker (container runtime)
- jq (JSON processor)
- wget, unzip, curl
- cron (task scheduling)
- Terraform (optional, configurable versions)
- OpenTofu (optional, configurable versions)
- StackGuardian Runner (sg-runner binary)

## Prerequisites

- **Azure Subscription**: With Contributor permissions to create VMs and images
- **Azure CLI**: Authenticated (`az login`)
- **Terraform**: Version 1.0 or later
- **Network Access**: Packer creates temporary networking by default, or use an existing VNet/subnet

## Quick Start

### Step 1: Configure Variables

Create a `terraform.tfvars` file:

```hcl
azure_location      = "westeurope"
resource_group_name = "my-image-rg"
```

### Step 2: Deploy

```bash
terraform init
terraform plan
terraform apply
```

### Step 3: Retrieve Image ID

```bash
terraform output image_id
```

### Basic Configuration Example

```hcl
module "packer_image" {
  source = "./azure/packer"

  azure_location      = "westeurope"
  resource_group_name = "my-image-rg"
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
| `azure_location` | Azure region for image creation | `westeurope` |
| `create_resource_group` | Create the resource group (if false, must already exist) | `false` |
| `vm_size` | Azure VM size for the build process | `Standard_D2s_v3` |
| `os.publisher` | OS publisher (`Canonical` or `RedHat`) | `Canonical` |
| `os.offer` | OS offer | `0001-com-ubuntu-server-jammy` |
| `os.sku` | OS SKU | `22_04-lts-gen2` |
| `os.version` | OS version | `latest` |
| `os.update_os_before_install` | Update OS packages before installation | `true` |
| `os.user_script` | Custom script to run during provisioning | `""` |
| `packer_config.version` | Packer version to use | `1.14.1` |
| `packer_config.cleanup_images_on_destroy` | Auto-cleanup image on terraform destroy | `true` |
| `image_name_prefix` | Prefix for the generated image name | `sg-runner` |
| `terraform.primary_version` | Primary Terraform version to install | `""` |
| `terraform.additional_versions` | Additional Terraform versions to install | `[]` |
| `opentofu.primary_version` | Primary OpenTofu version to install | `""` |
| `opentofu.additional_versions` | Additional OpenTofu versions to install | `[]` |
| `network.vnet_name` | Existing VNet name (empty = Packer creates temporary networking) | `""` |
| `network.subnet_name` | Existing subnet name | `""` |
| `network.resource_group_name` | Resource group of the existing VNet | `""` |

### Configuration Examples

#### Basic Configuration (Ubuntu Default)

```hcl
module "packer_image" {
  source = "./azure/packer"

  azure_location      = "westeurope"
  resource_group_name = "my-image-rg"
}
```

#### Ubuntu with Multiple Terraform Versions

```hcl
module "packer_image" {
  source = "./azure/packer"

  azure_location      = "westeurope"
  resource_group_name = "my-image-rg"

  os = {
    publisher                = "Canonical"
    offer                    = "0001-com-ubuntu-server-jammy"
    sku                      = "22_04-lts-gen2"
    update_os_before_install = true
  }

  terraform = {
    primary_version     = "1.5.7"
    additional_versions = ["1.4.6", "1.6.0", "1.7.0"]
  }

  opentofu = {
    primary_version = "1.8.0"
  }
}
```

#### RHEL with Existing Network

```hcl
module "packer_image" {
  source = "./azure/packer"

  azure_location      = "westeurope"
  resource_group_name = "my-image-rg"
  vm_size             = "Standard_D4s_v3"

  os = {
    publisher                = "RedHat"
    offer                    = "RHEL"
    sku                      = "9_3"
    update_os_before_install = true
  }

  network = {
    vnet_name           = "my-existing-vnet"
    subnet_name         = "my-build-subnet"
    resource_group_name = "my-network-rg"
  }

  packer_config = {
    version                   = "1.14.1"
    cleanup_images_on_destroy = false
  }
}
```

#### Custom User Script

```hcl
module "packer_image" {
  source = "./azure/packer"

  azure_location      = "westeurope"
  resource_group_name = "my-image-rg"

  os = {
    publisher   = "Canonical"
    offer       = "0001-com-ubuntu-server-jammy"
    sku         = "22_04-lts-gen2"
    user_script = <<-EOF
      #!/bin/bash
      # Install additional tools
      sudo apt-get install -y git

      # Configure custom settings
      echo "export CUSTOM_VAR=value" >> ~/.bashrc
    EOF
  }
}
```

## Usage

### Building the Image

```bash
# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Build the image
terraform apply
```

### Using the Image

After creation, use the image ID with the Azure Single Runner module:

```bash
# Get the image ID
IMAGE_ID=$(terraform output -raw image_id)

# Deploy runners using this image
cd ../azure_runner
terraform apply -var="vm_image_id=$IMAGE_ID"
```

### Cleanup

```bash
# Destroy and cleanup image (if cleanup_images_on_destroy = true)
terraform destroy
```

For manual cleanup:

```bash
# List the image
terraform output -json cleanup_commands | jq -r '.list_image'

# Delete the image
terraform output -json cleanup_commands | jq -r '.delete_image'

# List all images with prefix
terraform output -json cleanup_commands | jq -r '.list_all'
```

## Architecture

### Resource Organization

| File | Purpose |
|------|---------|
| `main.tf` | Packer build orchestration, image cleanup logic |
| `variables.tf` | Input variable definitions and validation |
| `outputs.tf` | Output values (image ID, info, cleanup commands) |
| `locals.tf` | OS family detection, SSH username mapping, image naming |
| `provider.tf` | Azure and utility provider configuration |
| `image.pkr.hcl` | Packer HCL template for Azure image creation |
| `scripts/build_image.sh` | Shell script to execute Packer |
| `scripts/setup.sh` | Image provisioning script (package installation) |

### Build Flow

```
terraform apply
    |
    v
[Execute Packer] --> null_resource.packer_build
    |                     |
    |                     v
    |              scripts/build_image.sh
    |                     |
    |                     v
    |              image.pkr.hcl (Packer template)
    |                     |
    |                     v
    |              scripts/setup.sh (on Azure VM)
    |
    v
[Parse Image ID] --> data.external.packer_image_id
    |
    v
[Output Image ID]
```

### Image Naming Convention

Images are named following the pattern:
```
{image_name_prefix}-{os_family}-{os_sku}-{timestamp}
```

Examples:
- `sg-runner-ubuntu-22_04-lts-gen2-20240115-1430`
- `sg-runner-rhel-9_3-20240115-1430`

## Troubleshooting

### Common Issues

1. **Packer Build Fails**
   - Check network connectivity (Packer creates temporary networking by default)
   - If using existing VNet, verify subnet has internet access
   - Review `packer_manifest.log` for detailed errors

2. **Image Cleanup Fails**
   - Verify Azure CLI credentials (`az login`)
   - Check if the image is in use by a VM or VMSS

3. **Terraform/OpenTofu Not Installed**
   - Ensure version strings are valid (e.g., `1.5.7`, not `v1.5.7`)
   - Check network access to download URLs

4. **Permission Denied**
   - Verify Azure CLI has Contributor role on the subscription or resource group
   - Ensure the service principal can create VMs and images

### Debugging Commands

```bash
# View Packer build logs
cat packer_manifest.log

# Check image status
az image show --ids $(terraform output -raw image_id)

# List all images with prefix
az image list --resource-group <rg> \
  --query "[?starts_with(name, 'sg-runner')].{name:name, id:id}" -o table

# Enable Terraform debug logging
export TF_LOG=DEBUG
terraform apply
```

## Outputs

| Output | Description |
|--------|-------------|
| `image_id` | The resource ID of the created Azure Managed Image |
| `image_info` | Comprehensive image metadata (location, OS, timestamps, cleanup settings) |
| `resource_group_name` | The resource group name where the image is stored |
| `cleanup_commands` | Azure CLI commands for manual image cleanup |

## Security Considerations

- **OS Updates**: Recommended to enable `update_os_before_install` for security patches
- **Automatic Cleanup**: Configurable automatic image cleanup on destroy
- **Temporary Resources**: Build VM is automatically terminated after image creation
- **Network Isolation**: Packer creates temporary networking by default, or use an existing private VNet for enterprise environments

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| azurerm | >= 3.0 |
| null | >= 3.0 |
| external | >= 2.0 |

## Next Steps

After building your image:

1. **Deploy Private Runners**: Use the [Azure Single Runner](../azure_runner/) module with the created image ID
2. **Configure Runner Group**: Set up StackGuardian runner group using the `runner_group` module
3. **Set Up Autoscaling**: Deploy the [Azure Autoscaler](../autoscaler/) for automatic scaling

## Support

- [StackGuardian Documentation](https://docs.stackguardian.io)
- [GitHub Issues](https://github.com/StackGuardian/terraform-stackguardian-modules/issues)
