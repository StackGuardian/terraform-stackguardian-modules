# StackGuardian Autoscaled Private Runner - AWS Module

This Terraform module deploys an auto-scaling fleet of StackGuardian Private Runners on AWS EC2 with Lambda-based dynamic scaling. It creates an Auto Scaling Group that automatically adjusts capacity based on the job queue depth in your StackGuardian runner group.

## Overview

The module provisions EC2 instances running the StackGuardian Private Runner agent within an Auto Scaling Group. A Lambda function monitors your runner group's job queue and triggers scaling actions to match demand. This ensures optimal resource utilization while maintaining job throughput.

### What Gets Created

- **Auto Scaling Group**: EC2 fleet with configurable min/max capacity and rolling instance refresh
- **Launch Template**: Instance configuration with user data for runner registration
- **Security Group**: Network rules blocking inbound (except SSH if configured) and allowing all outbound
- **IAM Role & Instance Profile**: EC2 role with S3 storage backend access and SSM Session Manager support
- **NAT Gateway** (optional): Network infrastructure for private subnet deployments
- **SSH Key Pair** (optional): Custom SSH key pair when public key is provided

## Prerequisites

- **Custom AMI**: AMI with pre-installed dependencies (Docker, cron, jq, sg-runner). Use the StackGuardian Packer module to build this AMI.
- **StackGuardian API Key**: Organization API key from the StackGuardian platform
- **Runner Group**: Existing runner group created via the `stackguardian_runner_group` module
- **AWS Infrastructure**: VPC with at least one subnet (private subnet recommended with NAT Gateway)
- **IAM Permissions**: AWS credentials with permissions to create EC2, IAM, and VPC resources

## Quick Start

### Step 1: Build the AMI

First, build a custom AMI using the Packer module:

```bash
cd ../packer
terraform init && terraform apply -auto-approve
AMI_ID=$(terraform output -raw ami_id)
```

### Step 2: Create a Runner Group

Create a runner group using the StackGuardian runner group module to obtain the required credentials.

### Step 3: Deploy the Autoscaling Runner

```bash
cd ../autoscaling_group
terraform init
terraform plan
terraform apply
```

### Basic Configuration Example

```hcl
module "autoscaling_runner" {
  source = "./autoscaling_group"

  ami_id            = "ami-0123456789abcdef0"
  runner_group_name = "my-runner-group"
  s3_bucket_name    = "my-runner-storage-bucket"

  stackguardian = {
    api_key  = "sgu_xxxxxxxxxxxx"
    org_name = "my-org"
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
| `runner_group_name` | Name of the StackGuardian runner group (from runner group module output) | `string` |
| `s3_bucket_name` | S3 bucket name for storage backend (from runner group module output) | `string` |
| `stackguardian.api_key` | Organization API key on the StackGuardian platform | `string` |
| `network.vpc_id` | VPC ID for deployment | `string` |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `create_asg` | Whether to create a new ASG or use existing | `true` |
| `existing_asg_name` | Name of existing ASG (when `create_asg = false`) | `""` |
| `ami_id` | AMI ID with pre-installed runner dependencies | `""` |
| `aws_region` | Target AWS region | `eu-central-1` |
| `instance_type` | EC2 instance type (min 4 vCPU, 8GB RAM recommended) | `t3.xlarge` |
| `runner_group_token` | Authentication token for runner registration | `""` |
| `storage_backend_role_arn` | IAM role ARN for S3 storage backend access | `""` |
| `stackguardian.org_name` | Organization name on StackGuardian platform | `""` |
| `stackguardian.api_uri` | StackGuardian API URI | `""` |
| `override_names.global_prefix` | Prefix for AWS resource names | `SG_RUNNER` |
| `override_names.include_org_in_prefix` | Append org name to resource prefix | `false` |
| `network.subnet_id` | Subnet ID for ASG instances | `""` |
| `network.private_subnet_id` | Private subnet ID for private deployments | `""` |
| `network.public_subnet_id` | Public subnet ID (required for NAT Gateway) | `""` |
| `network.associate_public_ip` | Assign public IPs to instances | `false` |
| `network.create_network_infrastructure` | Create NAT Gateway and route tables | `false` |
| `network.additional_security_group_ids` | Additional security groups to attach | `[]` |
| `volume.type` | EBS volume type | `gp3` |
| `volume.size` | EBS volume size in GB | `100` |
| `volume.delete_on_termination` | Delete volume on instance termination | `false` |
| `firewall.ssh_key_name` | Name of existing SSH key pair in AWS | `""` |
| `firewall.ssh_public_key` | Custom SSH public key content | `""` |
| `firewall.ssh_access_rules` | Map of CIDR blocks for SSH access | `{}` |
| `firewall.additional_ingress_rules` | Additional security group ingress rules | `{}` |
| `scaling.min_size` | Minimum number of instances | `1` |
| `scaling.max_size` | Maximum number of instances | `3` |
| `scaling.desired_capacity` | Initial desired instance count | `1` |
| `scaling.scale_out_threshold` | Queue depth triggering scale-out | `3` |
| `scaling.scale_in_threshold` | Queue depth triggering scale-in | `1` |
| `scaling.scale_out_step` | Instances to add per scale-out | `1` |
| `scaling.scale_in_step` | Instances to remove per scale-in | `1` |
| `scaling.scale_out_cooldown_duration` | Minutes between scale-out events | `4` |
| `scaling.scale_in_cooldown_duration` | Minutes between scale-in events | `5` |
| `runner_startup_timeout` | Seconds to wait for Docker startup | `300` |

### Configuration Examples

#### Basic Configuration

```hcl
module "autoscaling_runner" {
  source = "./autoscaling_group"

  ami_id            = "ami-0123456789abcdef0"
  runner_group_name = "production-runners"
  s3_bucket_name    = "sg-runner-storage"

  stackguardian = {
    api_key  = var.sg_api_key
    org_name = "my-organization"
  }

  network = {
    vpc_id    = "vpc-abc123"
    subnet_id = "subnet-def456"
  }
}
```

#### Advanced Configuration with Private Subnet and NAT Gateway

```hcl
module "autoscaling_runner" {
  source = "./autoscaling_group"

  ami_id                   = "ami-0123456789abcdef0"
  aws_region               = "us-west-2"
  instance_type            = "t3.2xlarge"
  runner_group_name        = "production-runners"
  runner_group_token       = var.runner_group_token
  storage_backend_role_arn = "arn:aws:iam::123456789012:role/sg-runner-s3-role"
  s3_bucket_name           = "sg-runner-storage"

  stackguardian = {
    api_uri  = "https://api.app.stackguardian.io"
    api_key  = var.sg_api_key
    org_name = "my-organization"
  }

  override_names = {
    global_prefix         = "PROD_RUNNER"
    include_org_in_prefix = true
  }

  network = {
    vpc_id                        = "vpc-abc123"
    private_subnet_id             = "subnet-private-001"
    public_subnet_id              = "subnet-public-001"
    associate_public_ip           = false
    create_network_infrastructure = true
    additional_security_group_ids = ["sg-additional-001"]
  }

  volume = {
    type                  = "gp3"
    size                  = 200
    delete_on_termination = false
  }

  firewall = {
    ssh_key_name = "production-key"
    ssh_access_rules = {
      office    = "10.0.0.0/8"
      vpn       = "172.16.0.0/12"
    }
  }

  scaling = {
    min_size                    = 2
    max_size                    = 10
    desired_capacity            = 3
    scale_out_threshold         = 5
    scale_in_threshold          = 2
    scale_out_step              = 2
    scale_in_step               = 1
    scale_out_cooldown_duration = 5
    scale_in_cooldown_duration  = 10
  }

  runner_startup_timeout = 600
}
```

## Usage

### Initialize and Deploy

```bash
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

### Auto-scaling Behavior

The module supports dynamic scaling based on runner group job queue depth:

- **Scale-out**: Triggered when queued jobs reach the `scale_out_threshold` (default: 3 jobs)
- **Scale-in**: Triggered when queued jobs drop below `scale_in_threshold` (default: 1 job)
- **Cooldown**: Minimum 4 minutes between scale-out events, 5 minutes between scale-in events
- **Instance Refresh**: Rolling updates with 50% minimum healthy instances

### Cleanup

```bash
terraform destroy
```

**Warning**: Destroying the module will terminate all runner instances and delete associated resources. Ensure no critical jobs are running before destruction.

## Architecture

### Resource Organization

| File | Contents |
|------|----------|
| `autoscaling.tf` | Launch Template, Auto Scaling Group, SSH Key Pair |
| `ec2_role.tf` | IAM Role, Instance Profile, S3 access policy, SSM policy |
| `network.tf` | Security Group with dynamic ingress rules |
| `nat_gateway.tf` | NAT Gateway, Elastic IP, Route Table (optional) |
| `locals.tf` | Resource naming, subnet selection, SSH key logic |
| `variables.tf` | Input variable definitions |
| `outputs.tf` | Module outputs |
| `provider.tf` | AWS provider and required versions |

### Resource Naming Convention

Resources are named using the pattern: `{prefix}-private-runner-{resource-type}`

- Default prefix: `SG_RUNNER`
- With org name: `SG_RUNNER_my-org` (when `include_org_in_prefix = true`)

## Troubleshooting

### Common Issues

1. **Instances fail to register with runner group**
   - Verify the `runner_group_token` is correct
   - Check that instances have network connectivity to the StackGuardian API
   - Review instance user data logs: `/var/log/cloud-init-output.log`

2. **Instances stuck in pending state**
   - Ensure the AMI exists in the target region
   - Verify subnet has available IP addresses
   - Check IAM instance profile permissions

3. **NAT Gateway not routing traffic**
   - Confirm both `private_subnet_id` and `public_subnet_id` are provided
   - Ensure `create_network_infrastructure = true`
   - Verify the public subnet has an Internet Gateway attached

### Debugging Commands

```bash
# View ASG instances
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "SG_RUNNER-private-runner-asg"

# Check instance health
aws ec2 describe-instance-status \
  --instance-ids $(aws autoscaling describe-auto-scaling-instances \
    --query 'AutoScalingInstances[*].InstanceId' --output text)

# Connect via SSM Session Manager
aws ssm start-session --target i-0123456789abcdef0

# View scaling activities
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name "SG_RUNNER-private-runner-asg"
```

## Outputs

| Output | Description |
|--------|-------------|
| `autoscaling_group_name` | Name of the Auto Scaling Group (created or existing) |
| `launch_template_id` | ID of the Launch Template (only when `create_asg = true`) |
| `launch_template_latest_version` | Latest version of the Launch Template |
| `security_group_id` | ID of the security group created by this module |
| `iam_role_arn` | ARN of the EC2 IAM role |
| `iam_instance_profile_name` | Name of the IAM instance profile |
| `nat_gateway_id` | ID of the NAT Gateway (when created) |
| `nat_gateway_public_ip` | Public IP of the NAT Gateway (when created) |

## Security Considerations

- **Encrypted Root Volume**: 20GB gp3 volume with encryption enabled
- **IMDSv2 Required**: Instance metadata service requires session tokens
- **SSM Session Manager**: Secure shell access without SSH keys
- **Least Privilege IAM**: EC2 role only has permissions to assume S3 storage role
- **Security Group**: Default deny inbound, explicit allow for SSH only when configured
- **Private Subnet Support**: Deploy in private subnets with NAT Gateway for enhanced security

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 4.0 |
| external | >= 2.0 |

## Next Steps

After deployment:

1. Monitor the Auto Scaling Group in the AWS Console
2. Verify runners appear in your StackGuardian runner group
3. Submit test jobs to validate scaling behavior
4. Configure CloudWatch alarms for scaling events (optional)

## Support

- [StackGuardian Documentation](https://docs.stackguardian.io)
- [GitHub Issues](https://github.com/StackGuardian/terraform-stackguardian-modules/issues)
