# StackGuardian Private Runner - AWS Single Runner Module

Deploy a standalone StackGuardian Private Runner on AWS EC2. This module creates a single EC2 instance that automatically registers with your StackGuardian runner group and executes workflow jobs in your AWS environment.

## Overview

This Terraform module provisions a single EC2-based private runner for StackGuardian. The runner connects to the StackGuardian platform, retrieves workflow jobs, and executes them within your AWS VPC. It supports both public and private subnet deployments with optional NAT Gateway provisioning and VPC endpoint integration.

### What Gets Created

- **EC2 Instance**: Single runner instance with configurable instance type and storage
- **IAM Role & Instance Profile**: Permissions for S3 storage backend access and SSM Session Manager
- **Security Group**: Configurable inbound rules with full outbound access
- **SSH Key Pair**: Optional, when custom public key is provided
- **NAT Gateway** (optional): Elastic IP, NAT Gateway, and route tables for private subnet connectivity
- **VPC Endpoint Rules** (optional): Security group rules for VPC endpoint access

## Prerequisites

1. **StackGuardian Runner Group**: Create a runner group on StackGuardian platform first
2. **Storage Backend Role**: IAM role ARN from the `stackguardian_runner_group` module
3. **AMI**: Pre-built AMI with required dependencies (docker, cron, jq, sg-runner)
   - Use the companion Packer template to build a custom AMI
4. **AWS Infrastructure**: Existing VPC with appropriate subnets
5. **StackGuardian API Key**: Organization or user API key (`sgo_*` or `sgu_*`)

## Quick Start

### Step 1: Build the AMI

Use the companion Packer template to build a custom AMI with all required dependencies:

```bash
cd ../packer
packer build .
```

### Step 2: Deploy the Runner

```bash
terraform init
terraform plan
terraform apply
```

### Basic Configuration Example

```hcl
module "single_runner" {
  source = "path/to/single_runner"

  ami_id                   = "ami-0123456789abcdef0"
  runner_group_name        = "my-runner-group"
  storage_backend_role_arn = "arn:aws:iam::123456789012:role/sg-runner-s3-role"

  stackguardian = {
    api_key = "sgu_your_api_key"
  }

  network = {
    vpc_id            = "vpc-0123456789abcdef0"
    private_subnet_id = "subnet-0123456789abcdef0"
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
| `stackguardian.api_key` | StackGuardian API key (starts with `sgu_` or `sgo_`) | `string` |
| `network.vpc_id` | Existing VPC ID for deployment | `string` |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `aws_region` | Target AWS Region | `eu-central-1` |
| `instance_type` | EC2 instance type (min 4 vCPU, 8GB RAM recommended) | `t3.xlarge` |
| `stackguardian.api_uri` | StackGuardian API endpoint | `https://api.app.stackguardian.io` |
| `stackguardian.org_name` | Organization name (extracted from environment if not provided) | `""` |
| `network.private_subnet_id` | Private subnet ID for the runner instance | `""` |
| `network.public_subnet_id` | Public subnet ID (required for NAT Gateway) | `""` |
| `network.associate_public_ip` | Assign public IP to instance | `false` |
| `network.create_network_infrastructure` | Create NAT Gateway and route tables | `false` |
| `network.proxy_url` | HTTP proxy URL for private networks | `""` |
| `network.additional_security_group_ids` | Additional security groups to attach | `[]` |
| `network.vpc_endpoint_security_group_ids` | VPC endpoint security groups (adds inbound 443 rule) | `[]` |
| `override_names.global_prefix` | Prefix for all resource names | `SG_RUNNER` |
| `override_names.include_org_in_prefix` | Append org name to prefix | `false` |
| `volume.type` | EBS volume type | `gp3` |
| `volume.size` | EBS volume size in GB | `100` |
| `volume.delete_on_termination` | Delete volume on instance termination | `false` |
| `firewall.ssh_key_name` | Existing AWS SSH key pair name | `""` |
| `firewall.ssh_public_key` | Custom SSH public key content | `""` |
| `firewall.ssh_access_rules` | Map of CIDR blocks for SSH access | `{}` |
| `firewall.additional_ingress_rules` | Additional ingress rules | `{}` |
| `runner_startup_timeout` | Seconds to wait for Docker before shutdown | `300` |

### Configuration Examples

#### Basic Configuration (Public Subnet)

```hcl
module "single_runner" {
  source = "path/to/single_runner"

  ami_id                   = "ami-0123456789abcdef0"
  runner_group_name        = "my-runner-group"
  storage_backend_role_arn = "arn:aws:iam::123456789012:role/sg-runner-s3-role"

  stackguardian = {
    api_key = "sgu_your_api_key"
  }

  network = {
    vpc_id              = "vpc-0123456789abcdef0"
    public_subnet_id    = "subnet-public"
    associate_public_ip = true
  }
}
```

#### Private Subnet with NAT Gateway

```hcl
module "single_runner" {
  source = "path/to/single_runner"

  ami_id                   = "ami-0123456789abcdef0"
  runner_group_name        = "my-runner-group"
  storage_backend_role_arn = "arn:aws:iam::123456789012:role/sg-runner-s3-role"

  stackguardian = {
    api_key  = "sgu_your_api_key"
    api_uri  = "https://api.us.stackguardian.io"
    org_name = "my-org"
  }

  network = {
    vpc_id                        = "vpc-0123456789abcdef0"
    private_subnet_id             = "subnet-private"
    public_subnet_id              = "subnet-public"
    create_network_infrastructure = true
  }
}
```

#### Private Subnet with VPC Endpoints

For fully private deployments without NAT Gateway, use VPC endpoints and provide their security group IDs:

```hcl
module "single_runner" {
  source = "path/to/single_runner"

  ami_id                   = "ami-0123456789abcdef0"
  runner_group_name        = "my-runner-group"
  storage_backend_role_arn = "arn:aws:iam::123456789012:role/sg-runner-s3-role"

  stackguardian = {
    api_key = "sgu_your_api_key"
  }

  network = {
    vpc_id                          = "vpc-0123456789abcdef0"
    private_subnet_id               = "subnet-private"
    vpc_endpoint_security_group_ids = ["sg-vpce-sts", "sg-vpce-ssm", "sg-vpce-ecr"]
  }

  firewall = {
    ssh_key_name = "my-keypair"
    ssh_access_rules = {
      office = "10.0.0.0/8"
      vpn    = "192.168.1.0/24"
    }
  }

  volume = {
    type                  = "gp3"
    size                  = 200
    delete_on_termination = true
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

**Warning**: If `volume.delete_on_termination` is set to `false` (default), the EBS volume will persist after instance termination and must be manually deleted.

## Architecture

### Resource Organization

| File | Purpose |
|------|---------|
| `provider.tf` | AWS and StackGuardian provider configuration |
| `variables.tf` | Input variable definitions |
| `locals.tf` | Local values and computed configurations |
| `data.tf` | Data sources for runner group and S3 bucket |
| `ec2.tf` | EC2 instance and SSH key pair resources |
| `ec2_role.tf` | IAM role, policies, and instance profile |
| `network.tf` | Security group and VPC endpoint rules |
| `nat_gateway.tf` | Optional NAT Gateway infrastructure |
| `outputs.tf` | Module outputs |

### Resource Naming Convention

Resources are named using the pattern: `{prefix}-private-runner[-suffix]`

- Default prefix: `SG_RUNNER`
- With org name: `SG_RUNNER_my-org` (when `include_org_in_prefix = true`)

## Troubleshooting

### Common Issues

1. **Runner not registering with StackGuardian**
   - Verify the runner group exists and the API key has access
   - Check network connectivity to StackGuardian API
   - Review instance user data logs: `/var/log/cloud-init-output.log`

2. **VPC Endpoint connection timeout**
   - Ensure VPC endpoint security groups are provided via `vpc_endpoint_security_group_ids`
   - Verify the VPC endpoint is associated with the runner's subnet
   - Check that the endpoint has `PrivateDnsEnabled = true`

3. **S3 access denied**
   - Verify `storage_backend_role_arn` is correct
   - Ensure the runner's IAM role can assume the S3 role

4. **Docker not starting**
   - Check `runner_startup_timeout` is sufficient
   - Verify the AMI has Docker pre-installed

### Debugging Commands

```bash
# Connect via SSM Session Manager
aws ssm start-session --target <instance-id>

# Check cloud-init logs
sudo cat /var/log/cloud-init-output.log

# Check Docker status
sudo systemctl status docker

# Test StackGuardian API connectivity
curl -v https://api.app.stackguardian.io/health

# Test VPC endpoint connectivity
nslookup sts.<region>.amazonaws.com
curl -v https://sts.<region>.amazonaws.com
```

## Outputs

| Output | Description |
|--------|-------------|
| `instance_id` | The ID of the EC2 instance |
| `instance_private_ip` | The private IP address of the EC2 instance |
| `instance_public_ip` | The public IP address of the EC2 instance (if assigned) |
| `security_group_id` | The ID of the security group created by this module |
| `iam_role_name` | The name of the IAM role attached to the EC2 instance |
| `iam_role_arn` | The ARN of the IAM role attached to the EC2 instance |
| `iam_instance_profile_name` | The name of the IAM instance profile |
| `nat_gateway_id` | The ID of the NAT Gateway (when created) |
| `nat_gateway_public_ip` | The public IP of the NAT Gateway (when created) |

## Security Considerations

- **IMDSv2 Enforced**: Instance metadata service requires token-based authentication
- **Least Privilege IAM**: Runner role only has permissions to assume storage backend role and use SSM
- **No Default SSH**: SSH access is only enabled when explicitly configured via `ssh_access_rules`
- **Outbound Only**: Security group allows all outbound but blocks inbound by default
- **VPC Endpoint Support**: Private connectivity to AWS services without internet exposure

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 4.0 |
| stackguardian | >= 1.3.3 |
| external | >= 2.0 |

## Next Steps

After deployment:

1. Verify the runner appears in your StackGuardian runner group
2. Create a workflow that targets your runner group
3. Monitor runner health in the StackGuardian dashboard

## Support

- [StackGuardian Documentation](https://docs.stackguardian.io)
- [GitHub Issues](https://github.com/StackGuardian/terraform-stackguardian-modules/issues)
