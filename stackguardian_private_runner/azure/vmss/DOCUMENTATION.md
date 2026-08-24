# Private Runner VMSS - Azure Template

Deploy a self-managed StackGuardian Private Runner on Azure as a Virtual Machine Scale Set. Instances boot from a pre-baked custom image and register themselves with your StackGuardian organization automatically.

## Overview

This template gives you a horizontally-scalable pool of StackGuardian runners running in your own Azure subscription. The runners pick up jobs from your StackGuardian platform and execute them inside your network - so credentials, source code, and outputs never leave your perimeter.

### What This Template Creates

- **VM Scale Set** - The pool of Linux instances that run StackGuardian jobs.
- **Network Security Group** - Default-deny inbound, with SSH and other ports opened only on demand.
- **Virtual Network and Subnet** (optional) - When you don't have an existing VNet to drop the runners into.
- **NAT Gateway with public IP** (optional) - Outbound internet access for runners deployed in private subnets.
- **Managed identity binding** - Runners use a User-Assigned Managed Identity for secure access to the storage backend.
- **SSH key** (optional) - The platform can generate one for you, or you can bring your own.

## Prerequisites

- A StackGuardian API key (`sgo_*` or `sgu_*`), or a configured platform secret reference like `${secret::API_KEY}`.
- An Azure subscription and a target Resource Group already created.
- A custom Azure image with Docker, cron, jq, and the SG runner pre-installed. Use the companion **Packer** template to build one.
- A StackGuardian Runner Group already provisioned (use the companion **Runner Group** template). You'll feed its outputs into this template.
- Either an existing VNet/Subnet, or permission to create networking in the target subscription.

## Template Parameters

### Required Parameters

| Parameter | Description | Type |
|-----------|-------------|------|
| StackGuardian Platform → API Key | Your organization's API key (`sgo_*`/`sgu_*`) or a secret reference (`${secret::SECRET_NAME}`). | `string` |
| Resource Group Name | Name of the existing Azure Resource Group where resources will be created. | `string` |
| Runner Group Name | Name of the StackGuardian runner group these VMSS instances will register against (output of the runner_group module). | `string` |
| Runner Group Token | Registration token for the runner group (output of the runner_group module). Use a secret reference. | `string` |
| Storage Backend Identity ID | Resource ID of the User-Assigned Managed Identity used by runners to access the storage backend (output of the runner_group module). | `string` |
| VM Image ID | Custom Azure image ID with docker, cron, jq, and sg-runner pre-installed (typically built via the sibling Packer module). | `string` |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| StackGuardian Platform → API Region | Region of the StackGuardian control plane your organization runs in. | `EU1 - Europe` |
| StackGuardian Platform → Organization Name | Override the StackGuardian organization name. Leave blank to derive it from the API key. | `""` |
| Azure Region | Azure region where the VM Scale Set and supporting resources are deployed. | `westeurope` |
| VM Size | VM SKU for each scale-set instance. Minimum 4 vCPU and 8 GB RAM recommended. | `Standard_D4s_v3` |
| Network → Create New VNet & Subnet | Create a new VNet and Subnet for the runner. When false, you must provide existing VNet and Subnet IDs. | `false` |
| Network → Existing VNet ID | Resource ID of an existing Virtual Network (required when not creating a new one). | - |
| Network → Existing Subnet ID | Resource ID of an existing Subnet within the VNet above (required when not creating a new one). | - |
| Network → VNet Address Space | CIDR blocks for the new VNet. | `["10.0.0.0/16"]` |
| Network → Subnet Address Prefix | CIDR for the new subnet inside the VNet address space. | `10.0.1.0/24` |
| Network → Create NAT Gateway | Create a NAT Gateway with public IP and associate it with the (created) subnet for outbound internet access. | `false` |
| Network → Proxy URL | Optional HTTP proxy URL for private network deployments. | `""` |
| Network → Additional NSG IDs | Additional NSG resource IDs to associate with each instance. | `[]` |
| OS Disk → Disk Caching | One of `None`, `ReadOnly`, `ReadWrite`. | `ReadWrite` |
| OS Disk → Storage Account Type | One of `Standard_LRS`, `StandardSSD_LRS`, `Premium_LRS`, `Premium_ZRS`. | `Premium_LRS` |
| OS Disk → Disk Size (GB) | OS disk size in GB. Minimum 30. | `100` |
| Firewall & SSH → Admin Username | Linux admin user on each instance. | `azureuser` |
| Firewall & SSH → Generate SSH Key | When true, an RSA keypair is generated and the private key is stored in Terraform state and exposed as a sensitive output. Prefer providing your own SSH public key. | `false` |
| Firewall & SSH → SSH Public Key | SSH public key authorized to log in as the admin user. Required unless Generate SSH Key is enabled. | `""` |
| Firewall & SSH → SSH Access Rules | Map of friendly names to source CIDRs allowed to reach port 22. | `{}` |
| Firewall & SSH → Additional Inbound Rules | Map of named NSG inbound rules (priority, protocol, ports, source CIDRs). | `{}` |
| Scaling → Minimum Instances | Floor on instance count. Must be at least 1. | `1` |
| Scaling → Maximum Instances | Ceiling on instance count. Must be greater than or equal to Minimum Instances. | `3` |
| Scaling → Desired Capacity | Initial instance count. Must be between Minimum and Maximum. | `1` |
| Runner Startup Timeout (seconds) | Maximum seconds to wait for Docker to start before shutting down each instance. | `300` |
| Resource Naming → Global Prefix | Prefix used for naming all Azure resources created by this template. | `SG_RUNNER` |
| Resource Naming → Include Org in Prefix | When true, appends the org name to the prefix (e.g. `SG_RUNNER_demo-org`). | `false` |
| Resource Naming → Org Name (for prefix) | Organization name to include in the prefix when "Include Org in Prefix" is enabled. | `""` |

## Important Notes

**Runner image**: Instances boot from a pre-baked custom image. If the image is missing Docker or the SG runner agent, instances will self-shutdown after the startup timeout. Always rebuild the image via the Packer template after changes.

**Auto-scaling**: After the first deployment, the companion Autoscaler template drives instance count between Minimum and Maximum based on workload. Re-running this template will not fight the autoscaler - the desired count is intentionally ignored on subsequent applies.

**Generated SSH keys**: If you let the platform generate an SSH keypair, the private key is stored in Terraform state and exposed as a sensitive template output. For production, prefer supplying your own public key and managing the private key separately.

**Network mode**: You must either create a new VNet/Subnet or supply existing IDs - the template won't deploy without one of those. If you select "Create NAT Gateway", you must also enable "Create New VNet & Subnet".

**API key safety**: Use a `${secret::NAME}` reference for the API key and runner group token. Pasting raw `sgo_*`/`sgu_*` values into the form embeds them in the run inputs.

## Outputs

| Output | Description |
|--------|-------------|
| VMSS Name | Name of the deployed VM Scale Set - feed this to the Autoscaler template. |
| VMSS Resource Group | Resource group containing the VMSS - feed this to the Autoscaler template. |
| VNet ID | The VNet hosting the runners (created or existing). |
| Subnet ID | The subnet hosting the runners (created or existing). |
| SSH Public Key | SSH public key configured on the VMSS instances. |
| SSH Private Key | Generated RSA private key (only when "Generate SSH Key" is enabled). Sensitive. |

## Security Features

- NSG denies all inbound by default; only the rules you explicitly add are opened.
- Storage backend access uses a User-Assigned Managed Identity - no static credentials on the instance.
- Runner group token is treated as sensitive and not surfaced in logs.
- Outbound traffic flows through an optional NAT Gateway you can disable for fully private deployments (use with a proxy or ExpressRoute).
- Custom-image-only boot - no plaintext bootstrap of the runner agent over the network.
