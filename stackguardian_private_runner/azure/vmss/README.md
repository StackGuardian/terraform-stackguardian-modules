# Private Runner VMSS - Azure Module

Terraform module that deploys a self-registering StackGuardian Private Runner as an Azure Linux Virtual Machine Scale Set (VMSS), wired to an existing or freshly-created VNet/Subnet, an NSG, and (optionally) a NAT Gateway for outbound traffic.

## Overview

This module is the Azure counterpart to the AWS ASG-based runner. It provisions a Linux VMSS using a custom Azure image (built via the sibling Packer module) that has docker, cron, jq and `sg-runner` pre-installed. Each instance runs a cloud-init script that registers the VM with a StackGuardian runner group at boot. Capacity is bounded here; the actual scale in/out is driven by the sibling `autoscaler` module (an Azure Function), so `instances` is set on first apply and then ignored.

### What Gets Created

- **Linux VM Scale Set** with manual upgrade mode and a User-Assigned Managed Identity for storage backend access.
- **Network Security Group** with optional SSH allow rules and arbitrary additional inbound rules.
- **Virtual Network + Subnet** (only when `network.create_network = true`).
- **NAT Gateway + Public IP + subnet association** (only when `network.create_network = true` and `network.create_network_infrastructure = true`).
- **TLS RSA keypair** (only when `firewall.generate_ssh_key = true`; private key is exposed as a sensitive output).

## Prerequisites

- An Azure custom image with docker, cron, jq, and `sg-runner` baked in. Use the sibling `azure/packer` module to produce one.
- A StackGuardian organization API key (`sgo_*` or `sgu_*`) or a secret reference (`${secret::NAME}`).
- A StackGuardian runner group provisioned via the `stackguardian_runner_group` module - its outputs (`runner_group_name`, `runner_group_token`, `storage_backend_identity_id`) feed this module.
- An existing Azure resource group, and either:
  - Existing VNet + Subnet IDs, or
  - Permission to create networking (VNet, Subnet, NAT Gateway, Public IP) in the target resource group.
- Azure permissions to create VMSS, NSG, and identity assignments.

## Quick Start

### Step 1: Build a runner image

```bash
cd ../packer
terraform init && terraform apply
```

Capture the resulting custom image ID - you'll pass it as `vm_image_id`.

### Step 2: Create a runner group

```bash
cd ../../runner_group
terraform init && terraform apply
```

Capture `runner_group_name`, `runner_group_token`, and `storage_backend_identity_id` from its outputs.

### Step 3: Deploy this module

### Basic Configuration Example

```hcl
module "vmss" {
  source = "./azure/vmss"

  resource_group_name         = "rg-stackguardian-runner"
  azure_location              = "westeurope"
  vm_image_id                 = "/subscriptions/xxxx/resourceGroups/rg-images/providers/Microsoft.Compute/images/sg-runner-1"

  runner_group_name           = module.runner_group.runner_group_name
  runner_group_token          = module.runner_group.runner_group_token
  storage_backend_identity_id = module.runner_group.storage_backend_identity_id

  stackguardian = {
    api_key  = "sgo_xxxxxxxxxxxx"
    org_name = "demo-org"
  }

  network = {
    vnet_id   = "/subscriptions/.../virtualNetworks/my-vnet"
    subnet_id = "/subscriptions/.../subnets/runner-subnet"
  }

  firewall = {
    ssh_public_key = file("~/.ssh/id_rsa.pub")
  }
}
```

## Configuration

### Required Parameters

| Parameter | Description | Type |
|-----------|-------------|------|
| `vm_image_id` | Azure custom image ID with `docker`, `cron`, `jq`, `sg-runner` pre-installed. Must start with `/subscriptions/`. | `string` |
| `resource_group_name` | Existing Azure Resource Group to deploy into. | `string` |
| `runner_group_name` | StackGuardian runner group name (from `runner_group` module output). | `string` |
| `runner_group_token` | Runner group registration token (sensitive, from `runner_group` module output). | `string` |
| `storage_backend_identity_id` | Resource ID of the User-Assigned Managed Identity for storage backend access. | `string` |
| `stackguardian.api_key` | StackGuardian API key (`sgo_*`/`sgu_*`) or `${secret::NAME}` reference. | `string` |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `vm_size` | Azure VM SKU per instance (min 4 vCPU, 8 GB RAM recommended). | `Standard_D4s_v3` |
| `azure_location` | Azure region. | `westeurope` |
| `stackguardian.api_uri` | Control-plane URL (EU1 / US1 / DASH). | `https://api.app.stackguardian.io` |
| `stackguardian.org_name` | Override org name (else derived from API key). | `""` |
| `network.create_network` | Create a new VNet and Subnet. | `false` |
| `network.vnet_id` / `subnet_id` | Existing VNet/Subnet IDs (required when `create_network = false`). | `""` |
| `network.vnet_address_space` | CIDR blocks for the new VNet. | `["10.0.0.0/16"]` |
| `network.subnet_address_prefix` | CIDR for the new subnet. | `10.0.1.0/24` |
| `network.create_network_infrastructure` | Create NAT Gateway with public IP. | `false` |
| `network.proxy_url` | HTTP proxy URL for private network deployments. | `""` |
| `network.additional_nsg_ids` | Extra NSG IDs to associate. | `[]` |
| `os_disk.caching` | `None` / `ReadOnly` / `ReadWrite`. | `ReadWrite` |
| `os_disk.storage_account_type` | `Standard_LRS` / `StandardSSD_LRS` / `Premium_LRS` / `Premium_ZRS`. | `Premium_LRS` |
| `os_disk.disk_size_gb` | OS disk size in GB (min 30). | `100` |
| `firewall.admin_username` | Linux admin user. | `azureuser` |
| `firewall.ssh_public_key` | SSH public key (required unless `generate_ssh_key = true`). | `""` |
| `firewall.generate_ssh_key` | Generate an RSA keypair (private key in state). | `false` |
| `firewall.ssh_access_rules` | Map of name to source CIDR allowed on port 22. | `{}` |
| `firewall.additional_inbound_rules` | Map of name to NSG rule object (priority, protocol, ports, CIDRs). | `{}` |
| `scaling.min_size` | Minimum instance count. Must be >= 1. | `1` |
| `scaling.max_size` | Maximum instance count. | `3` |
| `scaling.desired_capacity` | Initial instance count (ignored after first apply). | `1` |
| `runner_startup_timeout` | Seconds to wait for Docker before instance self-shutdown. | `300` |
| `override_names.global_prefix` | Resource name prefix. | `SG_RUNNER` |
| `override_names.include_org_in_prefix` | Append org name to prefix. | `false` |
| `override_names.org_name` | Org name appended when above is true. | `""` |

### Configuration Examples

#### Create network + NAT Gateway

```hcl
module "vmss" {
  source = "./azure/vmss"
  # ... required params ...

  network = {
    create_network                = true
    vnet_address_space            = ["10.20.0.0/16"]
    subnet_address_prefix         = "10.20.1.0/24"
    create_network_infrastructure = true
  }

  firewall = {
    ssh_public_key   = file("~/.ssh/id_rsa.pub")
    ssh_access_rules = {
      office = "203.0.113.0/24"
    }
  }
}
```

#### Generate SSH key (private key in state)

```hcl
firewall = {
  generate_ssh_key = true
}

# Then read the output:
output "private_key" {
  value     = module.vmss.ssh_private_key
  sensitive = true
}
```

## Usage

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

### Auto-scaling

This module sets `instances` to `scaling.desired_capacity` once and then ignores it. The sibling `azure/autoscaler` module (an Azure Function) drives scale events between `min_size` and `max_size` based on runner queue depth. Re-running `terraform apply` will not fight the autoscaler.

### Cleanup

```bash
terraform destroy
```

When `firewall.generate_ssh_key = true`, the generated private key is destroyed with the state.

## Architecture

### Resource Organization

| File | Contents |
|------|----------|
| `vmss.tf` | `azurerm_linux_virtual_machine_scale_set`, optional `tls_private_key`. |
| `network.tf` | NSG, optional VNet, Subnet, NAT Gateway, Public IP, subnet associations. |
| `data.tf` | Data sources used by the module. |
| `locals.tf` | Naming helpers, computed flags (`create_network`, `create_nat_gateway`, `use_generated_key`), tags. |
| `variables.tf` | Module inputs. |
| `outputs.tf` | Module outputs. |
| `provider.tf` | `terraform` block and provider versions. |
| `templates/register_runner.sh.tpl` | Cloud-init template that registers the instance with StackGuardian. |

### Resource Naming Convention

Resources are named `<sanitized_prefix>-vmss-<role>` where `sanitized_prefix` is built from `override_names.global_prefix`, optionally suffixed with `org_name` when `include_org_in_prefix = true`.

## Troubleshooting

1. **`vm_image_id must be a valid Azure resource ID starting with '/subscriptions/'`**
   - You passed an image name or short ID. Use the full resource ID, e.g. `/subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Compute/images/{name}`.

2. **`Either set create_network = true, or provide both vnet_id and subnet_id`**
   - You left `create_network = false` (default) but didn't supply `vnet_id` and `subnet_id`. Pick one mode.

3. **`Either provide ssh_public_key or set generate_ssh_key = true`**
   - You disabled key generation but didn't provide a public key. Either set `firewall.ssh_public_key` or flip `firewall.generate_ssh_key = true`.

4. **Instance starts but doesn't register with StackGuardian**
   - Check `/var/log/cloud-init-output.log` on the instance.
   - Verify the API URI matches your control plane and the runner group token isn't expired.
   - If on a private network, set `network.proxy_url`.

5. **Instance shuts itself down after 5 minutes**
   - Docker didn't start within `runner_startup_timeout`. Verify the image actually has docker installed and enabled - rebuild via Packer if needed.

### Debugging Commands

```bash
# Find an instance
az vmss list-instances --resource-group <rg> --name <vmss-name> -o table

# SSH (using the configured admin_username)
ssh azureuser@<public-or-jumphost-ip>

# On the instance
sudo journalctl -u cloud-final --no-pager
sudo tail -n 200 /var/log/cloud-init-output.log
sudo systemctl status docker
sudo systemctl status sg-runner || true
```

## Outputs

| Output | Description |
|--------|-------------|
| `vmss_id` | Resource ID of the VMSS. |
| `vmss_name` | Name of the VMSS (consume from `azure/autoscaler` `vmss.name`). |
| `vmss_resource_group_name` | Resource group containing the VMSS. |
| `network_security_group_id` | NSG resource ID. |
| `vnet_id` | VNet ID (created or existing). |
| `subnet_id` | Subnet ID (created or existing). |
| `ssh_private_key` | Generated RSA private key, PEM-encoded (sensitive; only when `firewall.generate_ssh_key = true`). |
| `ssh_public_key` | SSH public key in use on the VMSS. |
| `storage_backend_identity_id` | Pass-through of the storage backend managed identity ID. |

## Security Considerations

- The NSG denies all inbound by default; SSH is opened only via `firewall.ssh_access_rules` (per-CIDR), and any extra exposure must be opted in via `firewall.additional_inbound_rules`.
- Outbound is allowed (rule priority 4096) so runners can reach the StackGuardian control plane and container registries.
- Storage backend access is via a User-Assigned Managed Identity - no static credentials on the instance.
- `runner_group_token` is marked sensitive and is not echoed to logs; prefer `${secret::NAME}` references.
- Generating SSH keys via `firewall.generate_ssh_key = true` stores the private key in Terraform state. Treat the state file as a secret or supply your own key.

## Requirements

| Name | Version |
|------|---------|
| `terraform` | `>= 1.0` |
| `azurerm` | `>= 3.0` |
| `external` | `>= 2.0` |
| `random` | `>= 3.0` |
| `tls` | `>= 4.0` |

## Next Steps

- Wire the sibling `azure/autoscaler` module to this VMSS using `vmss_name` and `vmss_resource_group_name`.
- Confirm runners appear in the StackGuardian UI under the configured runner group.
- Adjust `scaling.min_size` / `max_size` once you have a feel for queue throughput.

## Support

- StackGuardian docs: https://docs.stackguardian.io
- Module issues: open a ticket in the StackGuardian platform or this repository.
