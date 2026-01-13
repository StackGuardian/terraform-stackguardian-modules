# StackGuardian Private Runner - Packer AMI Builder (AWS)

Build custom Amazon Machine Images (AMIs) for StackGuardian Private Runner deployments with pre-installed dependencies and configurable tooling.

## Overview

This Terraform module automates the creation of custom AMIs using HashiCorp Packer. The resulting AMI includes Docker, Terraform, OpenTofu, and StackGuardian runner components, providing an optimized base image for Private Runner deployments.

### What Gets Created

- **Custom AMI**: Pre-configured Amazon Machine Image with all dependencies
- **Packer Build Instance**: Temporary EC2 instance used during the build process (automatically terminated)
- **EBS Snapshots**: Associated with the created AMI (can be auto-cleaned)

### What Gets Installed on the AMI

- Docker (container runtime)
- jq (JSON processor)
- wget, unzip, curl
- cron/crond (task scheduling)
- Terraform (optional, configurable versions)
- OpenTofu (optional, configurable versions)
- StackGuardian Runner (sg-runner binary)

## Prerequisites

- **AWS Account**: With permissions to create EC2 instances and AMIs
- **VPC**: Existing VPC with internet access (direct or via NAT/proxy)
- **Subnet**: Public subnet with IGW access OR private subnet with NAT Gateway
- **Terraform**: Version 1.0 or later
- **AWS CLI**: Configured with appropriate credentials

### Required IAM Permissions

The executing user/role needs permissions for:
- `ec2:RunInstances`, `ec2:TerminateInstances`
- `ec2:CreateImage`, `ec2:DeregisterImage`
- `ec2:DescribeImages`, `ec2:DescribeInstances`
- `ec2:CreateTags`, `ec2:ModifyImageAttribute`
- `ec2:CreateSnapshot`, `ec2:DeleteSnapshot`

## Quick Start

### Step 1: Configure Variables

Create a `terraform.tfvars` file:

```hcl
aws_region = "eu-central-1"

network = {
  vpc_id           = "vpc-0123456789abcdef0"
  public_subnet_id = "subnet-0123456789abcdef0"
}
```

### Step 2: Deploy

```bash
terraform init
terraform plan
terraform apply
```

### Step 3: Retrieve AMI ID

```bash
terraform output ami_id
```

### Basic Configuration Example

```hcl
module "packer_ami" {
  source = "./packer"

  aws_region = "eu-central-1"

  network = {
    vpc_id           = "vpc-0123456789abcdef0"
    public_subnet_id = "subnet-0123456789abcdef0"
  }
}
```

## Configuration

### Required Parameters

| Parameter | Description | Type |
|-----------|-------------|------|
| `network.vpc_id` | VPC ID where Packer will build the AMI | `string` |
| `network.public_subnet_id` OR `network.private_subnet_id` | Subnet for the build instance (exactly one required) | `string` |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `aws_region` | AWS region for AMI creation | `eu-central-1` |
| `instance_type` | EC2 instance type for build process | `t3.medium` |
| `os.family` | Operating system family (`amazon`, `ubuntu`, `rhel`) | `amazon` |
| `os.version` | OS version (required for Ubuntu/RHEL) | `""` |
| `os.update_os_before_install` | Update OS packages before installation | `true` |
| `os.ssh_username` | SSH username override | auto-detected |
| `os.user_script` | Custom script to run during provisioning | `""` |
| `packer_config.version` | Packer version to use | `1.14.1` |
| `packer_config.deregistration_protection.enabled` | Enable AMI deregistration protection | `true` |
| `packer_config.deregistration_protection.with_cooldown` | Enable 24-hour cooldown period | `false` |
| `packer_config.delete_snapshots` | Delete EBS snapshots during cleanup | `true` |
| `packer_config.cleanup_amis_on_destroy` | Auto-cleanup AMI on terraform destroy | `true` |
| `terraform.primary_version` | Primary Terraform version to install | `""` |
| `terraform.additional_versions` | Additional Terraform versions | `[]` |
| `opentofu.primary_version` | Primary OpenTofu version to install | `""` |
| `opentofu.additional_versions` | Additional OpenTofu versions | `[]` |
| `network.proxy_url` | HTTP proxy for private network builds | `""` |

### Configuration Examples

#### Basic Configuration (Amazon Linux 2)

```hcl
module "packer_ami" {
  source = "./packer"

  aws_region = "us-east-1"

  network = {
    vpc_id           = "vpc-0123456789abcdef0"
    public_subnet_id = "subnet-0123456789abcdef0"
  }
}
```

#### Ubuntu with Multiple Terraform Versions

```hcl
module "packer_ami" {
  source = "./packer"

  aws_region = "eu-west-1"

  network = {
    vpc_id           = "vpc-0123456789abcdef0"
    public_subnet_id = "subnet-0123456789abcdef0"
  }

  os = {
    family                   = "ubuntu"
    version                  = "22.04"
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

#### Private Network Build with Proxy

```hcl
module "packer_ami" {
  source = "./packer"

  aws_region = "eu-central-1"

  network = {
    vpc_id            = "vpc-0123456789abcdef0"
    private_subnet_id = "subnet-private-0123456789"
    proxy_url         = "http://proxy.internal.company.com:8080"
  }

  os = {
    family                   = "rhel"
    version                  = "9.6"
    update_os_before_install = true
  }

  packer_config = {
    version = "1.14.1"
    deregistration_protection = {
      enabled       = true
      with_cooldown = true
    }
    cleanup_amis_on_destroy = false
  }
}
```

#### Custom User Script

```hcl
module "packer_ami" {
  source = "./packer"

  aws_region = "us-west-2"

  network = {
    vpc_id           = "vpc-0123456789abcdef0"
    public_subnet_id = "subnet-0123456789abcdef0"
  }

  os = {
    family      = "amazon"
    user_script = <<-EOF
      #!/bin/bash
      # Install additional tools
      sudo yum install -y git

      # Configure custom settings
      echo "export CUSTOM_VAR=value" >> ~/.bashrc
    EOF
  }
}
```

## Usage

### Building the AMI

```bash
# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Build the AMI
terraform apply
```

### Using the AMI

After creation, use the AMI ID with the AWS Private Runner deployment module:

```bash
# Get the AMI ID
AMI_ID=$(terraform output -raw ami_id)

# Deploy runners using this AMI
cd ../autoscaling_group_runner
terraform apply -var="ami_id=$AMI_ID"
```

### Cleanup

```bash
# Destroy and cleanup AMI (if cleanup_amis_on_destroy = true)
terraform destroy
```

For manual cleanup when deregistration protection is enabled:

```bash
# Check protection status
terraform output -json cleanup_commands | jq -r '.check_protection'

# Disable protection (if enabled)
terraform output -json cleanup_commands | jq -r '.disable_protection'

# Wait for cooldown if enabled (24 hours)

# Deregister AMI
terraform output -json cleanup_commands | jq -r '.deregister_ami'

# Delete snapshots
terraform output -json cleanup_commands | jq -r '.delete_snapshots'
```

## Architecture

### Resource Organization

| File | Purpose |
|------|---------|
| `main.tf` | Packer build orchestration, AMI cleanup logic |
| `variables.tf` | Input variable definitions and validation |
| `outputs.tf` | Output values (AMI ID, info, cleanup commands) |
| `locals.tf` | AMI selection mappings, SSH username configuration |
| `provider.tf` | AWS and utility provider configuration |
| `ami.pkr.hcl` | Packer template for AMI creation |
| `scripts/build_ami.sh` | Shell script to execute Packer |
| `scripts/setup.sh` | AMI provisioning script |
| `scripts/cleanup_amis.sh` | AMI cleanup automation |

### Build Flow

```
terraform apply
    |
    v
[Fetch Base AMI] --> data.aws_ami.this
    |
    v
[Execute Packer] --> null_resource.packer_build
    |                     |
    |                     v
    |              scripts/build_ami.sh
    |                     |
    |                     v
    |              ami.pkr.hcl (Packer template)
    |                     |
    |                     v
    |              scripts/setup.sh (on EC2)
    |
    v
[Parse AMI ID] --> data.external.packer_ami_id
    |
    v
[Register Cleanup] --> null_resource.ami_cleanup
    |
    v
[Output AMI ID]
```

### AMI Naming Convention

AMIs are named following the pattern:
```
SG-RUNNER-ami-{os_family}{os_version}-{timestamp}
```

Examples:
- `SG-RUNNER-ami-amazon-20240115-1430`
- `SG-RUNNER-ami-ubuntu22.04-20240115-1430`
- `SG-RUNNER-ami-rhel9.6-20240115-1430`

## Troubleshooting

### Common Issues

1. **Packer Build Fails**
   - Check network connectivity (IGW for public subnet, NAT for private)
   - Verify proxy configuration if in private network
   - Review `packer_manifest.log` for detailed errors

2. **AMI Cleanup Fails**
   - Check if deregistration protection is enabled
   - Wait for cooldown period if configured
   - Verify AWS CLI credentials

3. **Terraform/OpenTofu Not Installed**
   - Ensure version strings are valid (e.g., `1.5.7`, not `v1.5.7`)
   - Check network access to download URLs

4. **Permission Denied**
   - Verify IAM permissions for EC2 and AMI operations
   - Check if AMI deregistration protection is blocking cleanup

### Debugging Commands

```bash
# View Packer build logs
cat packer_manifest.log

# Check AMI status
aws ec2 describe-images --image-ids $(terraform output -raw ami_id) --region $(terraform output -json ami_info | jq -r '.region')

# Check deregistration protection
aws ec2 describe-image-attribute \
  --image-id $(terraform output -raw ami_id) \
  --attribute deregistrationProtection \
  --region eu-central-1

# Enable Terraform debug logging
export TF_LOG=DEBUG
terraform apply
```

## Outputs

| Output | Description |
|--------|-------------|
| `ami_id` | The ID of the created AMI |
| `ami_info` | Comprehensive AMI metadata (region, OS, timestamps, protection settings) |
| `cleanup_commands` | Ready-to-use AWS CLI commands for manual AMI cleanup |

## Security Considerations

- **Deregistration Protection**: Enabled by default to prevent accidental AMI deletion
- **Cooldown Period**: Optional 24-hour waiting period before AMI can be deregistered
- **OS Updates**: Recommended to enable `update_os_before_install` for security patches
- **Private Network Support**: Build in private subnets with proxy support for enterprise environments
- **Automatic Cleanup**: Configurable automatic AMI and snapshot cleanup on destroy

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 4.0 |
| null | >= 3.0 |
| external | >= 2.0 |
| local | >= 2.0 |

## Next Steps

After building your AMI:

1. **Deploy Private Runners**: Use the `autoscaling_group_runner` or `single_runner` module with the created AMI ID
2. **Configure Runner Group**: Set up StackGuardian runner group using the `stackguardian_runner_group` module
3. **Test the Deployment**: Verify runners connect to StackGuardian platform

## Support

- **StackGuardian Documentation**: [https://docs.stackguardian.io](https://docs.stackguardian.io)
- **Issues**: Report issues via your StackGuardian support channel
