# StackGuardian Private Runner - Packer AMI Builder

Build custom AMIs for StackGuardian Private Runner with pre-installed dependencies and optimized configuration.

## Overview

This Terraform module builds custom AMIs using Packer for StackGuardian Private Runner deployment. The AMI includes pre-installed dependencies (Docker, Terraform, OpenTofu, sg-runner, etc.) across multiple operating systems.

## Prerequisites

- **Terraform** (>= 1.0)
- **AWS CLI** configured with appropriate credentials
- **AWS Permissions** - See `packer_permissions.json` for required IAM permissions
- **Network Infrastructure** - VPC with either:
  - Public subnet with internet gateway (default)
  - Private subnet with NAT Gateway or VPC Endpoints

## Quick Start

```bash
# 1. Copy and configure variables
cp terraform.tfvars.tpl terraform.tfvars

# 2. Edit terraform.tfvars with your configuration
# 3. Build the AMI
terraform init
terraform plan
terraform apply

# 4. Get the AMI ID
terraform output ami_id
```

### Basic Configuration Example

```hcl
aws_region = "us-west-2"

network = {
  vpc_id           = "vpc-12345678"
  public_subnet_id = "subnet-87654321"
}

os = {
  family                   = "amazon"
  update_os_before_install = true
}
```

## Network Configuration

### Public Subnet Build (Default)

```hcl
network = {
  vpc_id           = "vpc-12345678"
  public_subnet_id = "subnet-12345678"
}
```

### Private Subnet Build

```hcl
network = {
  vpc_id            = "vpc-12345678"
  private_subnet_id = "subnet-87654321"
  proxy_url         = "http://proxy.company.com:8080"  # Optional
}
```

**Private network requirements:**

- NAT Gateway or VPC Endpoints for internet access
- Security groups allowing outbound HTTPS (443) and HTTP (80)
- Optional proxy configuration for corporate environments

## Operating System Support

### Amazon Linux 2 (Default)

```hcl
os = {
  family                   = "amazon"
  update_os_before_install = true
}
```

### Ubuntu LTS

```hcl
os = {
  family                   = "ubuntu"
  version                  = "22.04"
  update_os_before_install = true
}
```

### Red Hat Enterprise Linux

```hcl
os = {
  family                   = "rhel"
  version                  = "9.4"
  update_os_before_install = true
}
```

## Tool Installation

### Terraform Versions

```hcl
terraform = {
  primary_version     = "1.5.7"
  additional_versions = ["1.4.6", "1.6.0"]
}
```

### OpenTofu Versions

```hcl
opentofu = {
  primary_version     = "1.6.0"
  additional_versions = ["1.5.0"]
}
```

### Disable Tool Installation

```hcl
terraform = {
  primary_version     = ""
  additional_versions = []
}
```

## Custom Scripts

Add custom installation commands via `user_script`:

```hcl
os = {
  family                   = "ubuntu"
  version                  = "22.04"
  update_os_before_install = true
  user_script              = "apt update && apt install -y htop tree"
}
```

### Multi-line Script Example

```hcl
os = {
  family      = "amazon"
  user_script = <<EOT
    # Install additional tools
    yum install -y vim tmux

    # Configure environment
    echo 'alias ll="ls -la"' >> /home/ec2-user/.bashrc
  EOT
}
```

## Configuration

### Required Parameters

| Parameter                                     | Description                                   | Type     |
| --------------------------------------------- | --------------------------------------------- | -------- |
| `aws_region`                                  | AWS region for AMI creation                   | `string` |
| `network.vpc_id`                              | VPC ID for build instance                     | `string` |
| `network.public_subnet_id` OR `network.private_subnet_id` | Subnet for build instance (exactly one required) | `string` |

### Optional Parameters

| Parameter                                       | Description                           | Default     |
| ----------------------------------------------- | ------------------------------------- | ----------- |
| `instance_type`                                 | EC2 instance type for build          | `t3.medium` |
| `os.family`                                     | OS family (amazon/ubuntu/rhel)       | `amazon`    |
| `os.version`                                    | OS version (required for ubuntu/rhel) | `""`        |
| `os.update_os_before_install`                   | Update packages before install       | `true`      |
| `os.ssh_username`                               | SSH username (auto-detected)         | `""`        |
| `os.user_script`                                | Custom shell script                   | `""`        |
| `packer_config.version`                         | Packer version                        | `1.14.1`    |
| `packer_config.cleanup_amis_on_destroy`         | Auto-cleanup on destroy              | `true`      |
| `packer_config.deregistration_protection.enabled` | Enable AMI protection              | `true`      |
| `packer_config.deregistration_protection.with_cooldown` | Enable cooldown period      | `false`     |
| `packer_config.delete_snapshots`                | Delete snapshots on cleanup          | `true`      |

## AMI Management

### Automatic Cleanup (Default)

AMIs are automatically cleaned up when running `terraform destroy`:

```bash
terraform destroy
# Automatically deregisters AMIs and deletes snapshots
```

### Manual Cleanup

To preserve AMIs and handle cleanup manually:

```hcl
packer_config = {
  cleanup_amis_on_destroy = false
}
```

```bash
# Interactive cleanup
./scripts/cleanup_amis.sh

# Get cleanup commands
terraform output cleanup_commands
```

### Protected AMI Cleanup

For AMIs with deregistration protection:

```bash
# Check protection status
terraform output cleanup_commands

# Disable protection (if needed)
aws ec2 disable-image-deregistration-protection --region REGION --image-id AMI_ID

# Deregister AMI
aws ec2 deregister-image --region REGION --image-id AMI_ID
```

## Usage

### Deployment

```bash
# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Build the AMI
terraform apply

# Get outputs
terraform output
```

### Troubleshooting

```bash
# View Packer build logs
cat packer_manifest.log

# Get AMI ID from logs
grep 'artifact,0,id' packer_manifest.log | tail -1 | cut -d, -f6 | cut -d: -f2

# Check AWS resources
aws ec2 describe-images --owners self --region YOUR_REGION
```

### Cleanup

```bash
# Destroy infrastructure (keeps AMI by default)
terraform destroy

# Manual AMI cleanup
./scripts/cleanup_amis.sh

# Check AMI costs
aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-02-01 --granularity MONTHLY --metrics BlendedCost --group-by Type=DIMENSION,Key=SERVICE
```

## Outputs

| Output             | Description                         |
| ------------------ | ----------------------------------- |
| `ami_id`           | The ID of the created AMI           |
| `ami_info`         | Comprehensive AMI metadata          |
| `cleanup_commands` | AWS CLI commands for manual cleanup |

## Example Configurations

### Basic Amazon Linux Build

```hcl
aws_region = "us-west-2"

network = {
  vpc_id           = "vpc-12345678"
  public_subnet_id = "subnet-87654321"
}

os = {
  family                   = "amazon"
  update_os_before_install = true
}
```

### Ubuntu with Custom Tools

```hcl
aws_region = "eu-west-1"

network = {
  vpc_id           = "vpc-12345678"
  public_subnet_id = "subnet-87654321"
}

os = {
  family                   = "ubuntu"
  version                  = "22.04"
  update_os_before_install = true
  user_script              = "apt install -y docker-compose"
}

terraform = {
  primary_version     = "1.5.7"
  additional_versions = ["1.4.6"]
}
```

### Private Network Build

```hcl
aws_region = "us-east-1"

network = {
  vpc_id            = "vpc-12345678"
  private_subnet_id = "subnet-87654321"
  proxy_url         = "http://proxy.company.com:8080"
}

os = {
  family                   = "rhel"
  version                  = "9.4"
  update_os_before_install = true
}

packer_config = {
  deregistration_protection = {
    enabled       = true
    with_cooldown = true
  }
  cleanup_amis_on_destroy = false
}
```

## Cost Considerations

- AMI storage: ~$0.05/GB-month
- EBS snapshots: ~$0.05/GB-month
- Build instance: Standard EC2 pricing during build
- Set up billing alerts for AMI storage costs
- Clean up unused AMIs regularly

## Troubleshooting

### Common Issues

1. **Packer build fails with network errors**

   - Verify VPC has internet access (IGW for public, NAT for private)
   - Check security groups allow outbound HTTPS/HTTP

2. **Permission denied errors**

   - Verify IAM permissions match `packer_permissions.json`
   - Ensure EC2 instance profile has required permissions

3. **AMI cleanup fails**

   - Check if AMI has deregistration protection enabled
   - Verify snapshot deletion permissions

4. **Private subnet build fails**
   - Ensure NAT Gateway or VPC Endpoints configured
   - Configure proxy_url if using corporate proxy

### Debug Mode

Enable detailed Packer logging:

```bash
PACKER_LOG=1 terraform apply
```

## Next Steps

After successful AMI creation, use the AMI ID with the StackGuardian Private Runner deployment template to launch your runner instances with the pre-configured environment.

For detailed cleanup procedures and troubleshooting, see `TERRAFORM_DESTROY_GUIDE.md`.

