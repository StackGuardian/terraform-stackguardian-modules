# StackGuardian Private Runner - AWS Single Runner Module

Deploy a standalone StackGuardian Private Runner on AWS EC2. This module creates a single EC2 instance that automatically registers with your StackGuardian runner group to execute workflows in your private infrastructure.

## Overview

This module provisions a single EC2 instance configured as a StackGuardian Private Runner. It handles instance creation, IAM role configuration, security groups, and automatic runner registration. Use this module when you need a simple, dedicated runner without auto-scaling capabilities.

### What Gets Created

- **EC2 Instance**: Single runner instance with configurable instance type and EBS storage
- **IAM Role & Instance Profile**: Permissions for S3 storage backend access and instance metadata
- **Security Group**: Configurable firewall rules for SSH and custom ingress
- **SSH Key Pair**: Optional custom key pair for instance access
- **NAT Gateway** (optional): Network infrastructure for private subnet deployments

## Prerequisites

1. **Custom AMI**: Build an AMI with pre-installed dependencies using the Packer module (`../packer`)
   - Required: Docker, cron, jq, sg-runner
2. **Runner Group**: Create a runner group using the `runner_group` module
3. **StackGuardian API Key**: Valid API key starting with `sgu_` (user) or `sgo_` (organization)
4. **AWS Infrastructure**: Existing VPC with at least one subnet

## Quick Start

### Step 1: Build the AMI

First, create a custom AMI using the Packer module:

```bash
cd ../packer
terraform init
terraform apply -var="network={vpc_id=\"vpc-xxx\", public_subnet_id=\"subnet-xxx\"}"
AMI_ID=$(terraform output -raw ami_id)
```

### Step 2: Create Runner Group

Create the runner group and storage backend:

```bash
cd ../../runner_group
terraform init
terraform apply -var="stackguardian={api_key=\"sgu_xxx\"}"
```

### Step 3: Deploy the Runner

```bash
cd ../aws/single_runner
terraform init
terraform apply \
  -var="ami_id=$AMI_ID" \
  -var="runner_group_name=$(cd ../../runner_group && terraform output -raw runner_group_name)" \
  -var="storage_backend_role_arn=$(cd ../../runner_group && terraform output -raw storage_backend_role_arn)" \
  -var="stackguardian={api_key=\"sgu_xxx\"}" \
  -var="network={vpc_id=\"vpc-xxx\", subnet_id=\"subnet-xxx\"}"
```

### Basic Configuration Example

```hcl
module "single_runner" {
  source = "path/to/aws/single_runner"

  ami_id                   = "ami-0123456789abcdef0"
  runner_group_name        = "my-runner-group"
  storage_backend_role_arn = "arn:aws:iam::123456789012:role/SG_RUNNER-storage-backend"

  stackguardian = {
    api_key = "sgu_your_api_key"
  }

  network = {
    vpc_id    = "vpc-0123456789abcdef0"
    subnet_id = "subnet-0123456789abcdef0"
  }
}
```

## Configuration

### Required Parameters

| Parameter | Description | Type |
|-----------|-------------|------|
| `ami_id` | AMI ID with pre-installed dependencies (docker, cron, jq, sg-runner) | `string` |
| `runner_group_name` | Name of the StackGuardian runner group | `string` |
| `storage_backend_role_arn` | ARN of the IAM role for S3 storage backend access | `string` |
| `stackguardian.api_key` | StackGuardian API key (must start with `sgu_` or `sgo_`) | `string` |
| `network.vpc_id` | Existing VPC ID for deployment | `string` |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `instance_type` | EC2 instance type (min 4 vCPU, 8GB RAM recommended) | `t3.xlarge` |
| `aws_region` | Target AWS region | `eu-central-1` |
| `stackguardian.api_uri` | StackGuardian API endpoint | `https://api.app.stackguardian.io` |
| `stackguardian.org_name` | Organization name (extracted from env if not provided) | `""` |
| `override_names.global_prefix` | Prefix for all AWS resource names | `SG_RUNNER` |
| `network.subnet_id` | Subnet ID (legacy, use private/public subnet instead) | `""` |
| `network.private_subnet_id` | Private subnet ID for private deployments | `""` |
| `network.public_subnet_id` | Public subnet ID (required with NAT Gateway) | `""` |
| `network.associate_public_ip` | Assign public IP to instance | `false` |
| `network.create_network_infrastructure` | Create NAT Gateway and route tables | `false` |
| `network.proxy_url` | HTTP proxy URL for private networks | `""` |
| `network.additional_security_group_ids` | Additional security groups to attach | `[]` |
| `volume.type` | EBS volume type (gp2, gp3, io1, io2) | `gp3` |
| `volume.size` | EBS volume size in GB (minimum 8) | `100` |
| `volume.delete_on_termination` | Delete volume on instance termination | `false` |
| `firewall.ssh_key_name` | Name of existing SSH key pair | `""` |
| `firewall.ssh_public_key` | Custom SSH public key content | `""` |
| `firewall.ssh_access_rules` | Map of CIDR blocks for SSH access | `{}` |
| `firewall.additional_ingress_rules` | Additional ingress rules | `{}` |
| `runner_startup_timeout` | Seconds to wait for Docker before shutdown | `300` |

### Configuration Examples

#### Basic Configuration

```hcl
module "single_runner" {
  source = "path/to/aws/single_runner"

  ami_id                   = "ami-0123456789abcdef0"
  runner_group_name        = "production-runners"
  storage_backend_role_arn = "arn:aws:iam::123456789012:role/SG_RUNNER-storage-backend"

  stackguardian = {
    api_key = "sgu_your_api_key"
  }

  network = {
    vpc_id    = "vpc-0123456789abcdef0"
    subnet_id = "subnet-0123456789abcdef0"
  }
}
```

#### Private Subnet with NAT Gateway

```hcl
module "single_runner" {
  source = "path/to/aws/single_runner"

  ami_id                   = "ami-0123456789abcdef0"
  runner_group_name        = "production-runners"
  storage_backend_role_arn = "arn:aws:iam::123456789012:role/SG_RUNNER-storage-backend"

  stackguardian = {
    api_key  = "sgu_your_api_key"
    api_uri  = "https://api.us.stackguardian.io"
    org_name = "my-org"
  }

  network = {
    vpc_id                        = "vpc-0123456789abcdef0"
    private_subnet_id             = "subnet-private-0123456789"
    public_subnet_id              = "subnet-public-0123456789"
    create_network_infrastructure = true
  }

  override_names = {
    global_prefix = "PROD_RUNNER"
  }
}
```

#### Full Configuration with SSH Access

```hcl
module "single_runner" {
  source = "path/to/aws/single_runner"

  ami_id                   = "ami-0123456789abcdef0"
  runner_group_name        = "dev-runners"
  storage_backend_role_arn = "arn:aws:iam::123456789012:role/SG_RUNNER-storage-backend"
  instance_type            = "t3.2xlarge"
  aws_region               = "us-east-1"

  stackguardian = {
    api_key  = "sgu_your_api_key"
    org_name = "my-org"
  }

  network = {
    vpc_id              = "vpc-0123456789abcdef0"
    subnet_id           = "subnet-0123456789abcdef0"
    associate_public_ip = true
  }

  volume = {
    type                  = "gp3"
    size                  = 200
    delete_on_termination = true
  }

  firewall = {
    ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2E..."
    ssh_access_rules = {
      office = "10.0.0.0/8"
      vpn    = "192.168.1.0/24"
    }
  }

  runner_startup_timeout = 600
}
```

## Usage

### Deployment

```bash
# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Apply configuration
terraform apply
```

### Verify Runner Registration

After deployment, verify the runner is registered in the StackGuardian platform:

1. Navigate to your StackGuardian organization
2. Go to **Orchestrator > Runner Groups**
3. Select your runner group
4. Confirm the runner appears in the list

### Cleanup

```bash
# Destroy all resources
terraform destroy
```

## Architecture

### Resource Organization

| File | Purpose |
|------|---------|
| `variables.tf` | Input variable definitions |
| `outputs.tf` | Module outputs |
| `provider.tf` | Provider configuration (AWS, StackGuardian) |
| `locals.tf` | Computed values and business logic |
| `data.tf` | Data sources (runner group token, S3 bucket) |
| `ec2.tf` | EC2 instance and SSH key pair |
| `ec2_role.tf` | IAM role, policy, and instance profile |
| `network.tf` | Security group configuration |
| `nat_gateway.tf` | Optional NAT Gateway infrastructure |

### Resource Naming Convention

All resources use the pattern: `{global_prefix}-{resource-type}`

Examples:
- EC2 Instance: `SG_RUNNER-private-runner`
- IAM Role: `SG_RUNNER-ec2-private-runner-role`
- Security Group: `SG_RUNNER-private-runner`
- Instance Profile: `SG_RUNNER-runner-instance-profile`

## Troubleshooting

### Common Issues

1. **Runner Not Registering**
   - Check instance user data logs: `/var/log/cloud-init-output.log`
   - Verify Docker is running: `systemctl status docker`
   - Check network connectivity to StackGuardian API

2. **Docker Startup Timeout**
   - Increase `runner_startup_timeout` value
   - Check AMI has Docker pre-installed
   - Verify instance has sufficient resources

3. **Network Connectivity Issues**
   - Ensure security group allows outbound HTTPS (443)
   - For private subnets, verify NAT Gateway or proxy configuration
   - Check VPC endpoints if using private networks

### Debugging Commands

```bash
# SSH into the instance
ssh -i your-key.pem ec2-user@<instance-ip>

# Check cloud-init logs
sudo cat /var/log/cloud-init-output.log

# Check Docker status
sudo systemctl status docker

# Check runner registration
sudo journalctl -u sg-runner

# Test StackGuardian API connectivity
curl -I https://api.app.stackguardian.io/health
```

## Outputs

| Output | Description |
|--------|-------------|
| `instance_id` | The ID of the EC2 instance |
| `instance_private_ip` | Private IP address of the instance |
| `instance_public_ip` | Public IP address (if assigned) |
| `security_group_id` | ID of the created security group |
| `iam_role_name` | Name of the IAM role |
| `iam_role_arn` | ARN of the IAM role |
| `iam_instance_profile_name` | Name of the instance profile |
| `nat_gateway_id` | NAT Gateway ID (when created) |
| `nat_gateway_public_ip` | NAT Gateway public IP (when created) |

## Security Considerations

- **IMDSv2 Required**: Instance metadata service requires token-based access
- **Encrypted Storage**: EBS volumes use AWS-managed encryption
- **Least Privilege IAM**: IAM role has minimal permissions for S3 storage backend
- **Security Group**: Default rules allow only outbound HTTPS; SSH requires explicit configuration
- **Sensitive Variables**: API keys and tokens are marked as sensitive in Terraform state
- **Private Deployment**: Supports private subnet deployment with NAT Gateway or proxy

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 4.0 |
| stackguardian | >= 1.3.3 |
| external | >= 2.0 |

## Next Steps

1. **Monitor Runner**: Use StackGuardian platform to monitor runner health and job execution
2. **Configure Workflows**: Assign workflows to use the private runner group
3. **Scale Up**: Consider the `autoscaling_group_runner` module for auto-scaling capabilities
4. **Secure Access**: Configure VPN or bastion host for SSH access in production

## Support

- [StackGuardian Documentation](https://docs.stackguardian.io)
- [GitHub Issues](https://github.com/StackGuardian/terraform-stackguardian-modules/issues)
