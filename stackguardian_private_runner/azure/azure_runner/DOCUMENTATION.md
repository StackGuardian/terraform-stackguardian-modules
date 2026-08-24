# Private Runner - Azure Single VM Template

Deploy a standalone StackGuardian Private Runner on Azure as a single Linux Virtual Machine. The VM boots from a pre-baked custom image and registers itself with your StackGuardian organization automatically.

## Overview

This template gives you one StackGuardian runner running in your own Azure subscription. The runner picks up jobs from your StackGuardian platform and executes them inside your network - so credentials, source code, and outputs never leave your perimeter. Use it when you want a fixed, predictable runner; for a horizontally-scalable pool, use the companion **VMSS** and **Autoscaler** templates instead.

### What This Template Creates

- **Linux Virtual Machine** - The single instance that runs StackGuardian jobs.
- **Network Interface** - Attached to your subnet, with an optional public IP.
- **Network Security Group** - Default-deny inbound, with SSH and other ports opened only on demand.
- **Virtual Network and Subnet** (optional) - When you don't have an existing VNet to drop the runner into.
- **NAT Gateway with public IP** (optional) - Outbound internet access for a runner deployed in a private subnet.
- **VNet service endpoints** (optional) - Reach Azure services over the Azure backbone from the created subnet.
- **Managed identity binding** - The runner uses a User-Assigned Managed Identity for secure access to the storage backend.
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
| Runner Group Name | Name of the StackGuardian runner group this instance will register against (output of the runner_group module). | `string` |
| Runner Group Token | Registration token for the runner group (output of the runner_group module). Use a secret reference. | `string` |
| Storage Backend Identity ID | Resource ID of the User-Assigned Managed Identity used by the runner to access the storage backend (output of the runner_group module). | `string` |
| VM Image ID | Custom Azure image ID with docker, cron, jq, and sg-runner pre-installed (typically built via the sibling Packer module). | `string` |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| StackGuardian Platform → API Region | Region of the StackGuardian control plane your organization runs in. | `EU1 - Europe` |
| StackGuardian Platform → Organization Name | Override the StackGuardian organization name. Leave blank to derive it from the run environment. | `""` |
| Azure Region | Azure region where the VM and supporting resources are deployed. | `westeurope` |
| VM Size | VM SKU for the runner instance. Minimum 4 vCPU and 8 GB RAM recommended. | `Standard_D4s_v3` |
| Network → Create New VNet & Subnet | Create a new VNet and Subnet for the runner. When false, you must provide existing VNet and Subnet IDs. | `false` |
| Network → Existing VNet ID | Resource ID of an existing Virtual Network (required when not creating a new one). | - |
| Network → Existing Subnet ID | Resource ID of an existing Subnet within the VNet above (required when not creating a new one). | - |
| Network → VNet Address Space | CIDR blocks for the new VNet. | `["10.0.0.0/16"]` |
| Network → Subnet Address Prefix | CIDR for the new subnet inside the VNet address space. | `10.0.1.0/24` |
| Network → Associate Public IP | Assign a public IP to the VM. Disable for fully private deployments. | `false` |
| Network → Create NAT Gateway | Create a NAT Gateway with public IP and associate it with the (created) subnet for outbound internet access. | `false` |
| Network → Service Endpoints | Azure VNet service endpoints to enable on the created subnet (e.g. `Microsoft.Storage`, `Microsoft.KeyVault`). Only applies when creating the subnet. | `[]` |
| Network → Proxy URL | Optional HTTP proxy URL for private network deployments. | `""` |
| Network → Additional NSG IDs | Additional NSG resource IDs to associate with the network interface. | `[]` |
| OS Disk → Disk Caching | One of `None`, `ReadOnly`, `ReadWrite`. | `ReadWrite` |
| OS Disk → Storage Account Type | One of `Standard_LRS`, `StandardSSD_LRS`, `Premium_LRS`, `Premium_ZRS`. | `Premium_LRS` |
| OS Disk → Disk Size (GB) | OS disk size in GB. Minimum 30. | `100` |
| Firewall & SSH → Admin Username | Linux admin user on the VM. | `azureuser` |
| Firewall & SSH → Generate SSH Key | When true, an RSA keypair is generated and the private key is stored in Terraform state and exposed as a sensitive output. Prefer providing your own SSH public key. | `false` |
| Firewall & SSH → SSH Public Key | SSH public key authorized to log in as the admin user. Required unless Generate SSH Key is enabled. | `""` |
| Firewall & SSH → SSH Access Rules | Map of friendly names to source CIDRs allowed to reach port 22. | `{}` |
| Firewall & SSH → Additional Inbound Rules | Map of named NSG inbound rules (priority, protocol, ports, source CIDRs). | `{}` |
| Runner Startup Timeout (seconds) | Maximum seconds to wait for Docker to start before shutting down the instance. | `300` |
| Resource Naming → Global Prefix | Prefix used for naming all Azure resources created by this template. | `SG_RUNNER` |
| Resource Naming → Include Org in Prefix | When true, appends the org name to the prefix (e.g. `SG_RUNNER_demo-org`). | `false` |

## Important Notes

**Runner image**: The VM boots from a pre-baked custom image. If the image is missing Docker or the SG runner agent, the instance will self-shutdown after the startup timeout. Always rebuild the image via the Packer template after changes.

**Single instance**: This template deploys exactly one runner and does not scale. Jobs queue behind each other once the runner is busy. For elastic capacity, deploy the **VMSS** template and drive it with the **Autoscaler** template.

**Generated SSH keys**: If you let the platform generate an SSH keypair, the private key is stored in Terraform state and exposed as a sensitive template output. For production, prefer supplying your own public key and managing the private key separately.

**Network mode**: You must either create a new VNet/Subnet or supply existing IDs - the template won't deploy without one of those. "Create NAT Gateway" and "Service Endpoints" both apply only to a subnet this template creates; for an existing subnet, configure those on the subnet directly.

**Network connectivity**: The runner needs outbound HTTPS (port 443) access to reach StackGuardian. For private deployments:
- Enable NAT Gateway creation, or
- Configure a proxy URL, or
- Route outbound traffic through your own firewall / ExpressRoute

**Service endpoints**: Enabling `Microsoft.Storage` (and friends) keeps traffic between the runner and those Azure services on the Azure backbone rather than the public internet. Remember to allow the subnet on the target resource's network rules - the endpoint alone does not grant access.

**Resource naming**: Resource names use the global prefix, lowercased with underscores replaced by hyphens (`SG_RUNNER` → `sg-runner-*`). When "Include Org in Prefix" is enabled, the org name is appended to the prefix first.

**API key safety**: Use a `${secret::NAME}` reference for the API key and runner group token. Pasting raw `sgo_*`/`sgu_*` values into the form embeds them in the run inputs.

## Outputs

| Output | Description |
|--------|-------------|
| VM ID | Resource ID of the deployed Linux Virtual Machine. |
| VM Name | Name of the deployed Linux Virtual Machine. |
| VM Private IP | Internal IP address of the runner. |
| VM Public IP | External IP address (only when "Associate Public IP" is enabled). |
| Network Interface ID | Resource ID of the network interface attached to the VM. |
| Network Security Group ID | Resource ID of the NSG created by this template. |
| VNet ID | The VNet hosting the runner (created or existing). |
| Subnet ID | The subnet hosting the runner (created or existing). |
| SSH Public Key | SSH public key configured on the VM. |
| SSH Private Key | Generated RSA private key (only when "Generate SSH Key" is enabled). Sensitive. |
| Storage Backend Identity ID | Resource ID of the managed identity the runner uses for storage backend access. |

## Security Features

- NSG denies all inbound by default; only the rules you explicitly add are opened.
- Password authentication is disabled on the VM - SSH public key only.
- Storage backend access uses a User-Assigned Managed Identity - no static credentials on the instance.
- Runner group token is treated as sensitive and not surfaced in logs.
- Outbound traffic flows through an optional NAT Gateway you can disable for fully private deployments (use with a proxy or ExpressRoute).
- Optional VNet service endpoints keep Azure service traffic off the public internet.
- Custom-image-only boot - no plaintext bootstrap of the runner agent over the network.

## Usage

After deployment:

1. The runner automatically registers with your StackGuardian organization.
2. Navigate to **Orchestrator > Runner Groups** to verify registration.
3. Configure your workflows to use the runner group name.
4. Monitor runner health and job execution in the StackGuardian platform.

For auto-scaling capabilities, use the VMSS and Autoscaler templates instead.
