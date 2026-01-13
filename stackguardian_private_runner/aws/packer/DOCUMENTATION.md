# StackGuardian Private Runner - Packer AMI Builder Template

Deploy a custom AMI for StackGuardian Private Runner through the StackGuardian platform with pre-installed dependencies and optimized configuration.

## Overview

This template creates a custom Amazon Machine Image (AMI) optimized for StackGuardian Private Runner deployments. The AMI comes pre-loaded with all necessary dependencies, reducing runner startup time and ensuring consistent job execution.

### What This Template Creates

- **Custom AMI** with all StackGuardian runner dependencies pre-installed
- **Multi-OS Support** for Amazon Linux 2, Ubuntu, and RHEL
- **Pre-installed Tools** including Docker, Terraform, OpenTofu, and StackGuardian runner
- **Protected AMI** with optional deregistration protection for production use

## Prerequisites

Before deploying this template:

1. **AWS Permissions** - Your AWS connector needs EC2 and AMI management permissions
2. **Network Infrastructure** - An existing VPC with either:
   - A public subnet with internet gateway access, OR
   - A private subnet with NAT Gateway (optionally with proxy)

## Template Parameters

### Required Parameters

| Parameter | Description | Type |
|-----------|-------------|------|
| AWS Region | The AWS region where the AMI will be built | Dropdown selection |
| VPC ID | Existing VPC ID where Packer will build the AMI (must have internet access) | String (`vpc-***`) |
| Public Subnet ID OR Private Subnet ID | Subnet for the build instance (provide exactly one) | String (`subnet-***`) |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| Instance Type | EC2 instance type for the Packer build process (minimum 2 vCPU, 4GB RAM recommended) | `t3.medium` |
| OS Family | Base operating system: Amazon Linux 2, Ubuntu, or RHEL | Amazon Linux 2 |
| OS Version | Specific OS version (required for Ubuntu/RHEL, e.g., "22.04" or "9.6") | Empty |
| Update OS Before Install | Update OS packages before installing components for latest security patches | Enabled |
| SSH Username | SSH username for the build instance (auto-detected based on OS if empty) | Auto-detected |
| Custom User Script | Shell script for additional customization (runs after standard setup) | Empty |
| Packer Version | Version of HashiCorp Packer to use for building the AMI | `1.14.1` |
| Enable Deregistration Protection | Prevent accidental AMI deletion through AWS console or API | Enabled |
| Enable Cooldown Period | 24-hour waiting period before allowing deregistration | Disabled |
| Delete EBS Snapshots | Delete EBS snapshots during cleanup | Enabled |
| Automatic AMI Cleanup | Auto-cleanup AMI on stack destroy | Enabled |
| Primary Terraform Version | Main Terraform version to install as `/bin/terraform` | Empty |
| Additional Terraform Versions | Extra Terraform versions (installed as `/bin/terraform{version}`) | Empty |
| Primary OpenTofu Version | Main OpenTofu version to install as `/bin/tofu` | Empty |
| Additional OpenTofu Versions | Extra OpenTofu versions (installed as `/bin/tofu{version}`) | Empty |
| Proxy URL | HTTP proxy for private network builds (e.g., `http://proxy.company.com:8080`) | Empty |

## Important Notes

**Network Configuration**: You must provide exactly one of public_subnet_id OR private_subnet_id. Public subnets require an internet gateway; private subnets require NAT Gateway or VPC endpoints for internet access.

**OS Version Requirement**: When using Ubuntu or RHEL, you must specify the OS version (e.g., "22.04" for Ubuntu, "9.6" for RHEL). Amazon Linux 2 does not require a version.

**Terraform/OpenTofu Versions**: Version strings must follow semantic versioning (e.g., "1.5.7"). The primary version becomes the default binary, while additional versions are installed with version suffixes (e.g., `/bin/terraform1.4.6`).

**AMI Protection**: Deregistration protection is enabled by default to prevent accidental deletion. If cooldown is also enabled, you must wait 24 hours after disabling protection before the AMI can be deregistered.

## Outputs

| Output | Description |
|--------|-------------|
| AMI ID | The ID of the created AMI for use with the AWS deployment template |
| AMI Info | Comprehensive metadata including region, OS details, and protection settings |
| Cleanup Commands | Ready-to-use AWS CLI commands for manual AMI cleanup |

## Pre-installed Components

The built AMI includes:

- **Docker** - Container runtime for job execution
- **cron** - Task scheduling service
- **jq** - JSON processing utility
- **wget, curl, unzip** - Essential utilities
- **Terraform** - If specified, primary and additional versions
- **OpenTofu** - If specified, primary and additional versions
- **StackGuardian Runner** - sg-runner binary for workflow execution

## Operating System Support

| OS Family | Recommended Version | SSH Username | Notes |
|-----------|-------------------|--------------|-------|
| Amazon Linux 2 | (default) | ec2-user | Best AWS integration |
| Ubuntu | 22.04, 20.04 | ubuntu | Large package repository |
| RHEL | 9.6, 8.8 | ec2-user | Enterprise support |

## Security Features

- **Deregistration Protection** - Prevents accidental AMI deletion through AWS console or API
- **Cooldown Period** - Optional 24-hour waiting period for additional safety
- **OS Updates** - Option to apply security patches before component installation
- **Private Network Support** - Build in private subnets with proxy support for enterprise environments
- **Automatic Cleanup** - Secure cleanup of AMIs and snapshots when destroying the stack

## Next Steps

After the AMI is created:

1. Copy the AMI ID from the outputs
2. Deploy the AWS Private Runner template using this AMI
3. Configure your runner group in StackGuardian
4. Start running workflows on your private infrastructure
