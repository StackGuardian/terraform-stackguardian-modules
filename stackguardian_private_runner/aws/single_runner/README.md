# StackGuardian Private Runner - AWS Single Runner Module

Deploy a standalone StackGuardian Private Runner on AWS EC2. This module creates a single EC2 instance configured to register with your StackGuardian runner group for executing workflow runs in your own infrastructure.

## Overview

This module provisions a single EC2 instance that automatically registers with a StackGuardian runner group. The runner fetches and executes jobs from the StackGuardian platform, enabling you to run Terraform, OpenTofu, and other IaC workflows within your private network.

### What Gets Created

- **EC2 Instance**: Single runner instance with configurable instance type and EBS storage
- **IAM Role & Instance Profile**: Permissions to assume the storage backend role for S3 access
- **Security Group**: Configurable inbound rules (SSH optional) with full outbound access
- **SSH Key Pair**: (Optional) Custom key pair when providing SSH public key
- **NAT Gateway**: (Optional) For private subnet internet connectivity

## Prerequisites

1. **Custom AMI**: An AMI with pre-installed dependencies (Docker, cron, jq, sg-runner). Use the [Packer module](../packer/) to build one.
2. **Runner Group**: A configured StackGuardian runner group. Use the [runner_group module](../../runner_group/) to create one.
3. **StackGuardian API Key**: Organization or user API key starting with `sgo_` or `sgu_`
4. **AWS Infrastructure**: VPC with at least one subnet (private or public)

## Quick Start

### Step 1: Build the AMI

Use the Packer module to create a custom AMI with all required dependencies:

```bash
cd ../packer
terraform init && terraform apply
export AMI_ID=$(terraform output -raw ami_id)
```

### Step 2: Create Runner Group

Set up the runner group on StackGuardian platform:

```bash
cd ../../runner_group
terraform init && terraform apply
export RUNNER_GROUP_NAME=$(terraform output -raw runner_group_name)
export STORAGE_ROLE_ARN=$(terraform output -raw storage_backend_role_arn)
```

### Step 3: Deploy the Runner

```bash
cd ../aws/single_runner
terraform init
terraform plan
terraform apply
```

### Basic Configuration Example

```hcl
module "single_runner" {
  source = "path/to/stackguardian_private_runner/aws/single_runner"

  ami_id                   = "ami-0123456789abcdef0"
  runner_group_name        = "my-runner-group"
  storage_backend_role_arn = "arn:aws:iam::123456789012:role/SG_RUNNER-s3-access-role"

  stackguardian = {
    api_key = "sgu_xxxxxxxxxxxx"
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
| `network.vpc_id` | VPC ID for deployment | `string` |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `aws_region` | Target AWS region | `eu-central-1` |
| `instance_type` | EC2 instance type (min 4 vCPU, 8GB RAM recommended) | `t3.xlarge` |
| `stackguardian.api_uri` | StackGuardian API endpoint | `https://api.app.stackguardian.io` |
| `stackguardian.org_name` | Organization name (extracted from environment if not set) | `""` |
| `override_names.global_prefix` | Prefix for all AWS resource names | `SG_RUNNER` |
| `override_names.include_org_in_prefix` | Append org name to prefix | `false` |
| `network.private_subnet_id` | Private subnet ID for the instance | `""` |
| `network.public_subnet_id` | Public subnet ID (for NAT Gateway) | `""` |
| `network.associate_public_ip` | Assign public IP to instance | `false` |
| `network.create_network_infrastructure` | Create NAT Gateway and route tables | `false` |
| `network.proxy_url` | HTTP proxy URL for private networks | `""` |
| `network.additional_security_group_ids` | Additional security groups to attach | `[]` |
| `volume.type` | EBS volume type (gp2, gp3, io1, io2) | `gp3` |
| `volume.size` | EBS volume size in GB (minimum 8) | `100` |
| `volume.delete_on_termination` | Delete volume on instance termination | `false` |
| `firewall.ssh_key_name` | Existing AWS SSH key pair name | `""` |
| `firewall.ssh_public_key` | Custom SSH public key (takes precedence) | `""` |
| `firewall.ssh_access_rules` | Map of CIDR blocks for SSH access | `{}` |
| `firewall.additional_ingress_rules` | Additional ingress rules | `{}` |
| `runner_startup_timeout` | Seconds to wait for Docker before shutdown | `300` |

### Configuration Examples

#### Basic Configuration (Public Subnet)

```hcl
module "single_runner" {
  source = "path/to/stackguardian_private_runner/aws/single_runner"

  ami_id                   = var.ami_id
  runner_group_name        = var.runner_group_name
  storage_backend_role_arn = var.storage_backend_role_arn

  stackguardian = {
    api_key = var.sg_api_key
  }

  network = {
    vpc_id              = "vpc-xxx"
    public_subnet_id    = "subnet-xxx"
    associate_public_ip = true
  }
}
```

#### Private Subnet with NAT Gateway

```hcl
module "single_runner" {
  source = "path/to/stackguardian_private_runner/aws/single_runner"

  ami_id                   = var.ami_id
  runner_group_name        = var.runner_group_name
  storage_backend_role_arn = var.storage_backend_role_arn

  stackguardian = {
    api_key  = var.sg_api_key
    api_uri  = "https://api.us.stackguardian.io"
    org_name = "my-organization"
  }

  network = {
    vpc_id                        = "vpc-xxx"
    private_subnet_id             = "subnet-private-xxx"
    public_subnet_id              = "subnet-public-xxx"
    create_network_infrastructure = true
  }

  volume = {
    type                  = "gp3"
    size                  = 200
    delete_on_termination = true
  }
}
```

#### Full Configuration with SSH Access

```hcl
module "single_runner" {
  source = "path/to/stackguardian_private_runner/aws/single_runner"

  aws_region               = "us-east-1"
  ami_id                   = var.ami_id
  runner_group_name        = var.runner_group_name
  storage_backend_role_arn = var.storage_backend_role_arn
  instance_type            = "t3.2xlarge"

  stackguardian = {
    api_key  = var.sg_api_key
    api_uri  = "https://api.us.stackguardian.io"
    org_name = "my-organization"
  }

  override_names = {
    global_prefix         = "PROD_RUNNER"
    include_org_in_prefix = true
  }

  network = {
    vpc_id                        = "vpc-xxx"
    private_subnet_id             = "subnet-private-xxx"
    public_subnet_id              = "subnet-public-xxx"
    create_network_infrastructure = true
    additional_security_group_ids = ["sg-existing"]
  }

  volume = {
    type                  = "gp3"
    size                  = 200
    delete_on_termination = false
  }

  firewall = {
    ssh_public_key = file("~/.ssh/id_rsa.pub")
    ssh_access_rules = {
      office    = "10.0.0.0/8"
      vpn       = "192.168.1.0/24"
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

# Review the plan
terraform plan

# Deploy the runner
terraform apply
```

### Verify Deployment

After deployment, verify the runner is registered:

1. Check EC2 instance status in AWS Console
2. Verify runner appears in StackGuardian Platform under Runner Groups
3. Check instance logs via SSM Session Manager

### Cleanup

```bash
# Destroy the runner infrastructure
terraform destroy
```

**Note**: If `volume.delete_on_termination = false`, the EBS volume will persist after instance termination.

## Architecture

### Resource Organization

| File | Purpose |
|------|---------|
| `ec2.tf` | EC2 instance and SSH key pair resources |
| `ec2_role.tf` | IAM role, policies, and instance profile |
| `network.tf` | Security group with ingress/egress rules |
| `nat_gateway.tf` | Optional NAT Gateway, EIP, and route table |
| `data.tf` | Data sources for runner group and S3 bucket |
| `locals.tf` | Local values for configuration logic |
| `provider.tf` | Provider configuration (AWS, StackGuardian) |
| `variables.tf` | Input variable definitions |
| `outputs.tf` | Module outputs |

### Resource Naming Convention

Resources are named using the pattern: `{prefix}-private-runner[-suffix]`

- Default prefix: `SG_RUNNER`
- With org: `SG_RUNNER_my-org` (when `include_org_in_prefix = true`)
- Custom: `CUSTOM_PREFIX` (via `override_names.global_prefix`)

Examples:
- EC2 Instance: `SG_RUNNER-private-runner`
- Security Group: `SG_RUNNER-private-runner`
- IAM Role: `SG_RUNNER-ec2-private-runner-role`

### Subnet Priority

When both `private_subnet_id` and `public_subnet_id` are provided, the instance is deployed to the private subnet.

## Troubleshooting

### Common Issues

1. **Runner not registering with StackGuardian**
   - Verify the instance has internet connectivity (NAT Gateway or public IP)
   - Check that the API key is valid and has correct permissions
   - Ensure the runner group exists and is active

2. **Instance fails to start Docker**
   - Verify the AMI has Docker pre-installed
   - Check `runner_startup_timeout` is sufficient
   - Review instance logs via SSM Session Manager

3. **S3 access denied errors**
   - Verify `storage_backend_role_arn` matches the runner group's S3 role
   - Check IAM role trust relationship allows the EC2 instance to assume it

4. **NAT Gateway not created**
   - Ensure both `private_subnet_id` and `public_subnet_id` are provided
   - Verify `create_network_infrastructure = true`

### Debugging Commands

```bash
# Connect via SSM Session Manager
aws ssm start-session --target <instance-id>

# Check Docker status
sudo systemctl status docker

# View runner registration logs
sudo journalctl -u sg-runner

# Check cloud-init logs
sudo cat /var/log/cloud-init-output.log

# Verify S3 access
aws sts assume-role --role-arn <storage_backend_role_arn> --role-session-name test
```

## Outputs

| Output | Description |
|--------|-------------|
| `instance_id` | EC2 instance ID |
| `instance_private_ip` | Private IP address of the instance |
| `instance_public_ip` | Public IP address (if assigned) |
| `security_group_id` | Security group ID created by this module |
| `iam_role_name` | Name of the IAM role attached to the instance |
| `iam_role_arn` | ARN of the IAM role |
| `iam_instance_profile_name` | Name of the instance profile |
| `nat_gateway_id` | NAT Gateway ID (when created) |
| `nat_gateway_public_ip` | NAT Gateway public IP (when created) |

## Security Considerations

- **IMDSv2 Required**: Instance metadata service requires token-based access
- **No Default SSH**: SSH access is disabled by default; enable only when needed
- **Outbound Only**: Security group allows all outbound but no inbound by default
- **IAM Least Privilege**: EC2 role only has permission to assume the storage backend role
- **SSM Access**: Instance has SSM agent for secure shell access without SSH
- **Sensitive Variables**: API key is marked sensitive and won't appear in logs

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 4.0 |
| stackguardian | >= 1.3.3 |
| external | >= 2.0 |

## Next Steps

After deployment:

1. Verify runner status in StackGuardian Platform
2. Configure workflow runs to use the new runner group
3. Monitor runner health and job execution
4. Consider deploying the [autoscaling_group_runner](../autoscaling_group_runner/) for production workloads

## Support

- [StackGuardian Documentation](https://docs.stackguardian.io)
- [StackGuardian Support](https://support.stackguardian.io)
- [GitHub Issues](https://github.com/StackGuardian/terraform-stackguardian-modules/issues)
