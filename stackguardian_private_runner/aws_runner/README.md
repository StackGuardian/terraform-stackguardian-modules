# StackGuardian Private Runner - AWS Module

Deploy StackGuardian Private Runner infrastructure on AWS with auto-scaling capabilities and complete platform integration.

## Overview

This Terraform module creates an auto-scaling group of EC2 instances that run StackGuardian runners with Lambda-based autoscaling, S3 storage backend for Terraform state, and complete StackGuardian platform integration.

### What Gets Created

- **Auto Scaling Group**: EC2 instances with Lambda-based queue monitoring and scaling
- **Lambda Autoscaler**: Monitors job queues and triggers scaling events
- **S3 Storage Backend**: Dedicated bucket with encryption and versioning for Terraform state
- **Security Groups**: Configurable network access controls with least-privilege defaults
- **IAM Roles**: Service roles for runners and storage access with minimal permissions
- **StackGuardian Integration**: Runner Group and Connector resources for platform integration

## Prerequisites

Before using this module, ensure you have:

1. **Custom AMI**: Built using the companion [Packer module](../packer/) that includes:
   - Docker, cron, jq
   - sg-runner binary
   - Terraform and OpenTofu (optional)
2. **StackGuardian API Key**: Starting with `sgu_` prefix
3. **AWS Infrastructure**:
   - Existing VPC with internet connectivity
   - Public subnet for runner instances
   - Sufficient IAM permissions (see `../aws_permissions.json`)

## Quick Start

### Step 1: Get Custom AMI

First, build a custom AMI using the [Packer module](../packer/):

```bash
cd ../packer
terraform init
terraform apply
# Note the AMI ID output
```

### Step 2: Deploy Private Runners

Use the AMI ID from Step 1:

```bash
# Copy and configure variables
cp terraform.tfvars.example terraform.tfvars

# Deploy infrastructure
terraform init
terraform plan
terraform apply
```

### Basic Configuration Example

```hcl
# Required variables
ami_id     = "ami-1234567890abcdef0"  # From Packer module
aws_region = "eu-central-1"

# StackGuardian configuration
stackguardian = {
  api_key = "sgu_your_api_key_here"
}

# Network configuration
network = {
  vpc_id           = "vpc-1234567890abcdef0"
  public_subnet_id = "subnet-1234567890abcdef0"
}

# Optional: Customize resource names
override_names = {
  global_prefix = "my-company-sg"
}
```

## Configuration

### Required Parameters

| Parameter                  | Description                                    | Type     |
| -------------------------- | ---------------------------------------------- | -------- |
| `ami_id`                   | Custom AMI with sg-runner and dependencies     | `string` |
| `aws_region`               | Target AWS region                              | `string` |
| `stackguardian.api_key`    | StackGuardian API key (must start with `sgu_`) | `string` |
| `network.vpc_id`           | Existing VPC for deployment                    | `string` |
| `network.public_subnet_id` | Public subnet for runner instances             | `string` |

### Optional Parameters

| Parameter                           | Description                        | Default           |
| ----------------------------------- | ---------------------------------- | ----------------- |
| `override_names.global_prefix`      | Prefix for all resource names      | `"StackGuardian"` |
| `autoscaler.max_instances`          | Maximum number of runner instances | `10`              |
| `autoscaler.min_instances`          | Minimum number of runner instances | `0`               |
| `storage_backend.force_destroy`     | Allow bucket deletion with data    | `false`           |
| `firewall.additional_ingress_rules` | Custom security group rules        | `[]`              |

### Configuration Examples

#### Basic Configuration

```hcl
module "stackguardian_private_runner" {
  source = "./stackguardian_private_runner/aws"

  # Required parameters
  ami_id     = "ami-1234567890abcdef0"
  aws_region = "eu-central-1"

  stackguardian = {
    api_key = "sgu_your_api_key_here"
  }

  network = {
    vpc_id           = "vpc-1234567890abcdef0"
    public_subnet_id = "subnet-1234567890abcdef0"
  }
}
```

#### Advanced Configuration

```hcl
module "stackguardian_private_runner" {
  source = "./stackguardian_private_runner/aws"

  # Required parameters
  ami_id     = "ami-1234567890abcdef0"
  aws_region = "eu-central-1"

  stackguardian = {
    api_key   = "sgu_your_api_key_here"
    org_name  = "your-organization"  # Optional: auto-derived from API key
  }

  network = {
    vpc_id           = "vpc-1234567890abcdef0"
    public_subnet_id = "subnet-1234567890abcdef0"
  }

  # Optional parameters
  autoscaler = {
    max_instances        = 5
    min_instances        = 1
    instance_type        = "t3.medium"
    scale_out_threshold  = 3
    scale_in_threshold   = 2
    scale_out_cooldown   = 240  # 4 minutes
    scale_in_cooldown    = 300  # 5 minutes
  }

  storage_backend = {
    force_destroy = true
  }

  firewall = {
    additional_ingress_rules = [
      {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["10.0.0.0/8"]
        description = "SSH access from private networks"
      }
    ]
  }

  override_names = {
    global_prefix = "mycompany-sg"
  }
}
```

## Usage

### Deployment

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan deployment
terraform plan

# Apply changes
terraform apply
```

### Monitoring

```bash
# View outputs
terraform output

# Check state
terraform show

# List all resources
terraform state list
```

### Auto-scaling

The Lambda autoscaler automatically manages scaling based on StackGuardian job queue metrics:

- **Scale Out**: Triggered when ≥3 jobs are queued
- **Scale In**: Triggered when <2 jobs are queued
- **Cooldown**: 4min scale-out, 5min scale-in to prevent oscillations

### Cleanup

```bash
# Destroy infrastructure
terraform destroy
```

**Note**: If `storage_backend.force_destroy = false`, you'll need to manually empty the S3 bucket before destruction.

## Architecture

### Resource Organization

- **autoscaling.tf**: Auto Scaling Group and Launch Template
- **lambda_autoscaler.tf**: Queue monitoring and scaling logic
- **network.tf**: Security groups with configurable rules
- **storage_backend.tf**: S3 bucket for Terraform state
- **runner_role.tf**: IAM roles for runner instances
- **runner_group.tf**: StackGuardian platform integration

### Resource Naming Convention

All resources use the pattern: `{global_prefix}_{resource_type}`

- Auto Scaling Group: `{prefix}_ASG`
- Lambda Function: `{prefix}_autoscaler`
- S3 Bucket: `{prefix}-storage-backend-{random_suffix}`
- Security Groups: `{prefix}_SG`

## Architecture

The module creates a scalable runner infrastructure with the following components:

### Resource Organization

- **autoscaling.tf**: Auto Scaling Group and Launch Template
- **lambda_autoscaler.tf**: Queue monitoring and scaling logic
- **network.tf**: Security groups with configurable rules
- **storage_backend.tf**: S3 bucket for Terraform state
- **runner_role.tf**: IAM roles for runner instances
- **runner_group.tf**: StackGuardian platform integration

### Auto-scaling Behavior

- **Scale Out**: Triggered when ≥3 jobs are queued
- **Scale In**: Triggered when <2 jobs are queued
- **Cooldown**: 4min scale-out, 5min scale-in to prevent oscillations
- **Range**: Configurable min/max instances (default: 0-10)

### Resource Naming Convention

All resources use the pattern: `{global_prefix}_{resource_type}`

- Auto Scaling Group: `{prefix}_ASG`
- Lambda Function: `{prefix}_autoscaler`
- S3 Bucket: `{prefix}-storage-backend-{random_suffix}`
- Security Groups: `{prefix}_SG`

## Troubleshooting

### Common Issues

1. **AMI Missing Dependencies**

   - Verify AMI includes Docker, jq, sg-runner
   - Rebuild using the [Packer module](../packer/)

2. **Network Connectivity**

   - Ensure outbound HTTPS (443) access to StackGuardian platform
   - Check VPC internet gateway and route tables

3. **API Key Issues**

   - Verify API key format (must start with `sgu_`)
   - Check API key permissions in StackGuardian console

4. **Scaling Not Working**
   - Check Lambda function logs: `/aws/lambda/{prefix}_autoscaler`
   - Verify StackGuardian API connectivity from Lambda

### Debugging Commands

```bash
# Enable detailed Terraform logging
export TF_LOG=DEBUG
terraform apply

# View Lambda function logs
aws logs tail /aws/lambda/{prefix}_autoscaler --follow

# Check Auto Scaling Group activity
aws autoscaling describe-scaling-activities --auto-scaling-group-name {prefix}_ASG

# Verify runner registration
# Check StackGuardian console for active runners
```

## Outputs

| Output                   | Description                      |
| ------------------------ | -------------------------------- |
| `runner_group_id`        | StackGuardian Runner Group ID    |
| `connector_id`           | StackGuardian Connector ID       |
| `storage_backend_bucket` | S3 bucket name for state storage |
| `autoscaling_group_name` | Auto Scaling Group name          |
| `lambda_function_name`   | Lambda autoscaler function name  |

## Security Considerations

- All IAM roles follow least-privilege principles
- S3 bucket includes server-side encryption and versioning
- Security groups deny all ingress by default (configurable)
- Lambda function has minimal permissions for StackGuardian API access
- Runner instances can only access designated AWS resources

## Requirements

| Name          | Version |
| ------------- | ------- |
| terraform     | >= 1.0  |
| aws           | >= 5.0  |
| stackguardian | = 1.3.3 |
| random        | >= 3.0  |

## Next Steps

After successful deployment:

1. **Verify Runner Registration**

   ```bash
   # Check runner group in StackGuardian console
   terraform output runner_group_url
   ```

2. **Configure Workflows**
   Use the runner group name in your StackGuardian workflow configurations:

   ```yaml
   # In your StackGuardian workflow
   runner_constraints:
     runner_group: <terraform output runner_group_name>
   ```

3. **Monitor and Scale**
   - Monitor Lambda logs and scaling activities
   - Adjust scaling thresholds as needed
   - Set up CloudWatch alarms for cost monitoring

## Support

For issues and questions:

- Review the troubleshooting section above
- Check the companion [Packer module](../packer/) for AMI issues
- Refer to `../aws_permissions.json` for IAM requirements
- Contact your StackGuardian support team
