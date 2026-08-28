# StackGuardian Private Runner - Packer AMI Builder (AWS)

> Part of [StackGuardian Private Runner](../../README.md) — [AWS stack overview](../DOCUMENTATION.md) · [platform template doc](DOCUMENTATION.md)

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
- **Terraform**: Version 1.4 or later (OpenTofu 1.6+), for `terraform_data`
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
| `packer_config.rebuild_ami_token` | Change to any new value to rebuild the AMI (see [When Packer runs](#when-packer-runs)) | `""` |
| `packer_config.deregistration_protection.enabled` | Enable AMI deregistration protection | `true` |
| `packer_config.deregistration_protection.with_cooldown` | Enable 24-hour cooldown period | `false` |
| `packer_config.delete_snapshots` | Delete EBS snapshots during cleanup | `true` |
| `packer_config.cleanup_amis_on_destroy` | Deregister this deployment's AMI on terraform destroy | `true` |
| `ami_name_prefix` | Prefix for the generated AMI name | `"SG-RUNNER-ami"` |
| `terraform.primary_version` | Primary Terraform version to install | `""` |
| `terraform.additional_versions` | Additional Terraform versions | `[]` |
| `opentofu.primary_version` | Primary OpenTofu version to install | `""` |
| `opentofu.additional_versions` | Additional OpenTofu versions | `[]` |
| `sg_runner.pre_release` | Install the newest sg-runner pre-release instead of the latest stable release (falls back to stable when none exists) | `false` |
| `network.proxy_url` | HTTP proxy for private network builds | `""` |

### When Packer Runs

Building an AMI takes several minutes, so this module builds **once per state** and
then reuses what it built:

| Situation | Result |
|-----------|--------|
| First apply | Packer builds the AMI, and its ID is recorded in state |
| Every plan/apply after that | No build, no diff — the AMI ID comes from state |
| `rebuild_ami_token` changed to a new value | Packer builds a new AMI, once |
| State destroyed and re-applied | Packer builds again |

```hcl
# Force one fresh build (e.g. to pick up new Terraform/OpenTofu versions)
packer_config = {
  version           = "1.14.1"
  rebuild_ami_token = "2026-07-30-tofu-1.11"
}
```

The token is deliberately a free-form string rather than an on/off flag: bump it to
rebuild, then leave it alone. A boolean would build again the moment you unset it.

The recorded AMI ID lives in `terraform_data.ami_id`, not in `packer_manifest.log`,
so plans stay stable on a fresh checkout, on a CI runner, or after the log is deleted.
Because the ID no longer changes on every apply, the runner instance is no longer
replaced on every apply either.

> **Note:** `packer_config.cleanup_amis_on_destroy` (default `true`) only ever
> touches the AMI this deployment built — on destroy, and on the rebuild that
> supersedes it. AMIs belonging to other deployments are never deregistered, since
> the module never adopts an AMI it did not build.

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

See [TERRAFORM_DESTROY_GUIDE.md](TERRAFORM_DESTROY_GUIDE.md) for the full destroy
walkthrough, including why AMIs survive `destroy` by default and how deregistration
protection interacts with cleanup.

```bash
# Destroy and cleanup AMI (if cleanup_amis_on_destroy = true)
terraform destroy
```

To preview exactly what the cleanup would deregister and delete without touching
anything, run the script directly with `DRY_RUN=true`:

```bash
DRY_RUN=true \
  TARGET_AMI_ID="$(terraform output -raw ami_id)" \
  REGION="us-east-1" \
  sh ./scripts/cleanup_amis.sh
```

Every destructive call — disabling deregistration protection, deregistering the
AMI, and deleting its snapshots — is printed as `[dry-run] aws ec2 ...` instead of
being executed.

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
| `../../packer/scripts/build.sh` | Shared: installs Packer and runs the build |
| `../../packer/scripts/setup.sh` | Shared: image provisioning script |
| `scripts/cleanup_amis.sh` | AMI cleanup automation (AWS-specific) |

### Build Flow

```
terraform apply
    |
    v
[Fetch Base AMI] --> data.aws_ami.this
    |
    v
[Execute Packer] --> null_resource.packer_build
    |                  created once per state; replaced only when
    |                  rebuild_ami_token changes
    |                     |
    |                     v
    |              ../../packer/scripts/build.sh
    |                     |
    |                     v
    |              ami.pkr.hcl (Packer template)
    |                     |
    |                     v
    |              ../../packer/scripts/setup.sh (on EC2)
    |
    v
[Parse AMI ID] --> data.external.packer_ami_id (reads packer_manifest.log)
    |
    v
[Record AMI ID] --> terraform_data.ami_id
    |                  the ID lives here; later plans read it from state
    |                  instead of rebuilding or re-reading the log
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

2. **Packer Does Not Run / Old AMI Is Used**
   - Expected: the AMI is built once and then reused from state
   - Change `packer_config.rebuild_ami_token` to any new value to build a fresh one
   - Or, without touching variables: `terraform apply -replace=null_resource.packer_build`

3. **AMI Cleanup Fails**
   - Check if deregistration protection is enabled
   - Wait for cooldown period if configured
   - Verify AWS CLI credentials

4. **Terraform/OpenTofu Not Installed**
   - Ensure version strings are valid (e.g., `1.5.7`, not `v1.5.7`)
   - Check network access to download URLs

5. **Permission Denied**
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
| `ami_id` | The ID of the AMI built by this module and recorded in state |
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
| terraform | >= 1.4.0 |
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
