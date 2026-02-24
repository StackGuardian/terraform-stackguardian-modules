# StackGuardian Private Runner - Azure Single Runner Module

Deploy a standalone StackGuardian Private Runner on an Azure Linux VM. This module creates a single VM instance that automatically registers with your StackGuardian runner group and executes workflow jobs in your Azure environment.

## Overview

This Terraform module provisions a single Azure Linux VM-based private runner for StackGuardian. The runner connects to the StackGuardian platform, retrieves workflow jobs, and executes them within your Azure VNet. It supports both existing and newly created VNet deployments with optional public IP assignment.

### What Gets Created

- **Linux Virtual Machine**: Single runner instance with configurable VM size and OS disk
- **Network Interface**: Connected to your VNet subnet with optional public IP
- **Network Security Group**: Configurable inbound rules with full outbound access
- **SSH Key Pair**: Auto-generated 4096-bit RSA key or user-provided public key
- **VNet and Subnet** (optional): When `create_network = true`, creates new networking infrastructure
- **Public IP** (optional): When `associate_public_ip = true`, assigns a static public IP

## Prerequisites

1. **StackGuardian Runner Group**: Create a runner group on StackGuardian platform first
2. **Storage Backend Identity**: User-Assigned Managed Identity resource ID (from the runner group module)
3. **Custom VM Image**: Pre-built image with required dependencies (docker, cron, jq, sg-runner)
   - Use the companion [Packer module](../packer/) to build a custom image
4. **Azure Resource Group**: Existing resource group for deployment
5. **StackGuardian API Key**: Organization or user API key (`sgo_*` or `sgu_*`)

## Quick Start

### Step 1: Build the Image

Use the companion Packer module to build a custom image with all required dependencies:

```bash
cd ../packer
terraform init
terraform apply
```

### Step 2: Deploy the Runner

```bash
terraform init
terraform plan
terraform apply
```

### Basic Configuration Example

```hcl
module "azure_runner" {
  source = "./azure/azure_runner"

  vm_image_id         = "/subscriptions/.../providers/Microsoft.Compute/images/sg-runner-ubuntu-22_04-lts-gen2"
  resource_group_name = "my-resource-group"
  azure_location      = "westeurope"

  runner_group_name            = "my-runner-group"
  runner_group_token           = "runner-group-token"
  storage_backend_identity_id  = "/subscriptions/.../providers/Microsoft.ManagedIdentity/userAssignedIdentities/my-identity"

  stackguardian = {
    api_key = "sgu_your_api_key"
  }

  network = {
    vnet_id   = "/subscriptions/.../providers/Microsoft.Network/virtualNetworks/my-vnet"
    subnet_id = "/subscriptions/.../providers/Microsoft.Network/virtualNetworks/my-vnet/subnets/my-subnet"
  }
}
```

## Configuration

### Required Parameters

| Parameter | Description | Type |
|-----------|-------------|------|
| `vm_image_id` | Custom image ID with pre-installed dependencies (docker, cron, jq, sg-runner) | `string` |
| `resource_group_name` | Name of the Azure Resource Group for deployment | `string` |
| `runner_group_name` | Name of the StackGuardian runner group | `string` |
| `runner_group_token` | Runner group token for registration (from runner_group module) | `string` |
| `storage_backend_identity_id` | Resource ID of the User-Assigned Managed Identity for storage backend access | `string` |
| `stackguardian.api_key` | StackGuardian API key (starts with `sgu_` or `sgo_`) | `string` |
| `network` | Either set `create_network = true`, or provide both `vnet_id` and `subnet_id` | `object` |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `vm_size` | Azure VM size (min 4 vCPU, 8GB RAM recommended) | `Standard_D4s_v3` |
| `azure_location` | Target Azure region | `westeurope` |
| `stackguardian.org_name` | Organization name (extracted from environment if not provided) | `""` |
| `stackguardian.api_uri` | StackGuardian API endpoint | `""` (auto-detected) |
| `override_names.global_prefix` | Prefix for all resource names | `sg-runner` |
| `network.create_network` | Create a new VNet and Subnet | `false` |
| `network.vnet_address_space` | Address space for new VNet | `["10.0.0.0/16"]` |
| `network.subnet_address_prefix` | Address prefix for new subnet | `10.0.1.0/24` |
| `network.associate_public_ip` | Assign a public IP to the VM | `false` |
| `network.additional_nsg_ids` | Additional NSG IDs to associate with the NIC | `[]` |
| `os_disk.caching` | OS disk caching mode (None, ReadOnly, ReadWrite) | `ReadWrite` |
| `os_disk.storage_account_type` | OS disk storage type | `Premium_LRS` |
| `os_disk.disk_size_gb` | OS disk size in GB (minimum 30) | `100` |
| `firewall.admin_username` | SSH admin username | `azureuser` |
| `firewall.ssh_public_key` | Custom SSH public key content | `""` |
| `firewall.generate_ssh_key` | Auto-generate a 4096-bit RSA key pair | `true` |
| `firewall.ssh_access_rules` | Map of CIDR blocks for SSH access | `{}` |
| `firewall.additional_inbound_rules` | Additional NSG inbound rules | `{}` |
| `runner_startup_timeout` | Seconds to wait for Docker before shutdown | `300` |

### Configuration Examples

#### Basic Configuration (Existing VNet)

```hcl
module "azure_runner" {
  source = "./azure/azure_runner"

  vm_image_id         = "/subscriptions/.../providers/Microsoft.Compute/images/sg-runner-ubuntu"
  resource_group_name = "my-resource-group"

  runner_group_name           = "my-runner-group"
  runner_group_token          = "my-token"
  storage_backend_identity_id = "/subscriptions/.../providers/Microsoft.ManagedIdentity/userAssignedIdentities/my-identity"

  stackguardian = {
    api_key = "sgu_your_api_key"
  }

  network = {
    vnet_id   = "/subscriptions/.../Microsoft.Network/virtualNetworks/my-vnet"
    subnet_id = "/subscriptions/.../Microsoft.Network/virtualNetworks/my-vnet/subnets/my-subnet"
  }
}
```

#### Create New Network with Public IP

```hcl
module "azure_runner" {
  source = "./azure/azure_runner"

  vm_image_id         = "/subscriptions/.../providers/Microsoft.Compute/images/sg-runner-ubuntu"
  resource_group_name = "my-resource-group"
  azure_location      = "westeurope"

  runner_group_name           = "my-runner-group"
  runner_group_token          = "my-token"
  storage_backend_identity_id = "/subscriptions/.../providers/Microsoft.ManagedIdentity/userAssignedIdentities/my-identity"

  stackguardian = {
    api_key  = "sgu_your_api_key"
    org_name = "my-org"
  }

  network = {
    create_network        = true
    vnet_address_space    = ["10.0.0.0/16"]
    subnet_address_prefix = "10.0.1.0/24"
    associate_public_ip   = true
  }
}
```

#### Custom Firewall Rules and Disk Configuration

```hcl
module "azure_runner" {
  source = "./azure/azure_runner"

  vm_image_id         = "/subscriptions/.../providers/Microsoft.Compute/images/sg-runner-ubuntu"
  resource_group_name = "my-resource-group"
  vm_size             = "Standard_D8s_v3"

  runner_group_name           = "my-runner-group"
  runner_group_token          = "my-token"
  storage_backend_identity_id = "/subscriptions/.../providers/Microsoft.ManagedIdentity/userAssignedIdentities/my-identity"

  stackguardian = {
    api_key = "sgu_your_api_key"
  }

  network = {
    vnet_id   = "/subscriptions/.../Microsoft.Network/virtualNetworks/my-vnet"
    subnet_id = "/subscriptions/.../Microsoft.Network/virtualNetworks/my-vnet/subnets/my-subnet"
  }

  firewall = {
    admin_username   = "azureuser"
    generate_ssh_key = true
    ssh_access_rules = {
      office = "10.0.0.0/8"
      vpn    = "192.168.1.0/24"
    }
  }

  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 200
  }
}
```

## Usage

### Deployment

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

### Cleanup

```bash
# Destroy all resources
terraform destroy
```

## Architecture

### Resource Organization

| File | Purpose |
|------|---------|
| `provider.tf` | Azure, StackGuardian, and utility provider configuration |
| `variables.tf` | Input variable definitions and validation |
| `locals.tf` | Computed values, naming conventions, network mode logic |
| `data.tf` | Data sources for environment variable extraction |
| `vm.tf` | Linux VM, SSH key generation, User-Assigned Managed Identity |
| `network.tf` | VNet, Subnet, NSG, Public IP, Network Interface |
| `outputs.tf` | Module outputs |
| `templates/register_runner.sh.tpl` | Runner registration and startup script |

### Resource Naming Convention

Resources are named using the pattern: `{sanitized_prefix}-{resource-type}`

The `global_prefix` is lowercased with underscores replaced by hyphens.

Examples with default prefix `sg-runner`:
- VM: `sg-runner-private-runner`
- NSG: `sg-runner-nsg`
- VNet: `sg-runner-vnet`
- Subnet: `sg-runner-subnet`
- NIC: `sg-runner-nic`
- Public IP: `sg-runner-public-ip`

## Troubleshooting

### Common Issues

1. **Runner not registering with StackGuardian**
   - Verify the runner group exists and the API key has access
   - Check network connectivity to the StackGuardian API
   - Review instance cloud-init logs: `/var/log/cloud-init-output.log`

2. **SSH connection failures**
   - Verify NSG rules allow SSH from your IP (check `ssh_access_rules`)
   - Confirm the generated SSH key is being used: `terraform output -raw ssh_private_key`
   - Ensure `associate_public_ip = true` if connecting over the internet

3. **Storage backend access denied**
   - Verify `storage_backend_identity_id` is correct
   - Ensure the Managed Identity has the required role assignments on the storage account

4. **Docker not starting**
   - Check `runner_startup_timeout` is sufficient (default: 300s)
   - Verify the custom image has Docker pre-installed

### Debugging Commands

```bash
# Connect via Azure Serial Console
az serial-console connect --resource-group <rg> --name <vm-name>

# Check cloud-init logs (once connected)
sudo cat /var/log/cloud-init-output.log

# Check Docker status
sudo systemctl status docker

# Test StackGuardian API connectivity
curl -v https://api.app.stackguardian.io/health

# View VM status
az vm show --resource-group <rg> --name <vm-name> --query provisioningState
```

## Outputs

| Output | Description |
|--------|-------------|
| `vm_id` | The ID of the Azure Linux Virtual Machine |
| `vm_name` | The name of the Azure Linux Virtual Machine |
| `vm_private_ip` | The private IP address of the VM |
| `vm_public_ip` | The public IP address of the VM (if assigned) |
| `network_interface_id` | The ID of the network interface |
| `network_security_group_id` | The ID of the network security group |
| `vnet_id` | The ID of the VNet (created or existing) |
| `subnet_id` | The ID of the subnet (created or existing) |
| `ssh_private_key` | The generated SSH private key (if `generate_ssh_key = true`) |
| `ssh_public_key` | The SSH public key used for the VM |
| `storage_backend_identity_id` | The resource ID of the storage backend managed identity |

## Security Considerations

- **SSH-Only Authentication**: Password authentication is disabled; only SSH key-based access is allowed
- **Auto-Generated Keys**: 4096-bit RSA key pair generated by default for strong encryption
- **NSG Defaults**: Inbound traffic is blocked by default; SSH access must be explicitly configured via `ssh_access_rules`
- **Full Outbound**: Security group allows all outbound traffic for runner operations
- **Managed Identity**: User-Assigned Managed Identity provides secure access to storage backend without credentials

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| azurerm | >= 3.0 |
| stackguardian | >= 1.3.3 |
| external | >= 2.0 |
| random | >= 3.0 |
| tls | >= 4.0 |

## Next Steps

After deployment:

1. Verify the runner appears in your StackGuardian runner group
2. Create a workflow that targets your runner group
3. Monitor runner health in the StackGuardian dashboard

## Support

- [StackGuardian Documentation](https://docs.stackguardian.io)
- [GitHub Issues](https://github.com/StackGuardian/terraform-stackguardian-modules/issues)
