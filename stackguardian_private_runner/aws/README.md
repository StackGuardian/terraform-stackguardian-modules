# StackGuardian Private Runner - AWS Module

This Terraform module deploys StackGuardian Private Runner infrastructure on AWS. It creates an auto-scaling group of EC2 instances that run StackGuardian runners with Lambda-based autoscaling, S3 storage backend for Terraform state, and complete StackGuardian platform integration.

## Features

- **Auto-scaling Infrastructure**: EC2 instances with Lambda-based queue monitoring and scaling
- **State Management**: Dedicated S3 bucket with encryption and versioning for Terraform state storage
- **Security**: Least-privilege IAM roles with configurable security groups
- **Platform Integration**: Direct integration with StackGuardian API using Terraform provider
- **Network Flexibility**: Supports both public and private subnet deployment

## Prerequisites

Before using this module, ensure you have:

1. **Custom AMI**: Built using the companion Packer module that includes:
   - Docker
   - cron
   - jq
   - sg-runner binary
2. **StackGuardian API Key**: Starting with `sgu_` prefix
3. **AWS VPC**: Existing VPC with proper internet connectivity
4. **Subnet**: Public subnet for runner instances

## Quick Start

```hcl
module "stackguardian_private_runner" {
  source = "./stackguardian_private_runner/aws"

  # Required variables
  ami_id     = "ami-1234567890abcdef0"  # Your custom AMI
  aws_region = "us-west-2"

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
}
```

## Configuration

### Required Variables

| Variable                   | Description                                    | Type     |
| -------------------------- | ---------------------------------------------- | -------- |
| `ami_id`                   | Custom AMI with sg-runner and dependencies     | `string` |
| `aws_region`               | Target AWS region                              | `string` |
| `stackguardian.api_key`    | StackGuardian API key (must start with `sgu_`) | `string` |
| `network.vpc_id`           | Existing VPC for deployment                    | `string` |
| `network.public_subnet_id` | Public subnet for runner instances             | `string` |

### Important Optional Variables

| Variable                            | Description                        | Default           |
| ----------------------------------- | ---------------------------------- | ----------------- |
| `override_names.global_prefix`      | Prefix for all resource names      | `"StackGuardian"` |
| `autoscaler.max_instances`          | Maximum number of runner instances | `10`              |
| `autoscaler.min_instances`          | Minimum number of runner instances | `0`               |
| `storage_backend.force_destroy`     | Allow bucket deletion with data    | `false`           |
| `firewall.additional_ingress_rules` | Custom security group rules        | `[]`              |

### Complete Configuration Example

```hcl
module "stackguardian_private_runner" {
  source = "./stackguardian_private_runner/aws"

  # Required
  ami_id     = "ami-1234567890abcdef0"
  aws_region = "us-west-2"

  # StackGuardian
  stackguardian = {
    api_key   = "sgu_your_api_key_here"
    org_name  = "your-organization"  # Optional: auto-derived from API key
  }

  # Network
  network = {
    vpc_id           = "vpc-1234567890abcdef0"
    public_subnet_id = "subnet-1234567890abcdef0"
  }

  # Auto-scaling
  autoscaler = {
    max_instances        = 5
    min_instances        = 1
    instance_type        = "t3.medium"
    scale_out_threshold  = 3
    scale_in_threshold   = 2
    scale_out_cooldown   = 240  # 4 minutes
    scale_in_cooldown    = 300  # 5 minutes
  }

  # Storage
  storage_backend = {
    force_destroy = true  # Allows Terraform destroy to delete S3 bucket
  }

  # Security
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

  # Naming
  override_names = {
    global_prefix = "mycompany-sg"
  }
}
```

## Usage

### 1. Initialize and Deploy

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

### 2. Monitor Resources

```bash
# View outputs
terraform output

# Check state
terraform show

# List all resources
terraform state list
```

### 3. Scaling Operations

The Lambda autoscaler automatically manages scaling based on StackGuardian job queue metrics:

- **Scale Out**: Triggered when ≥3 jobs are queued
- **Scale In**: Triggered when <2 jobs are queued
- **Cooldown**: 4min scale-out, 5min scale-in to prevent oscillations

### 4. Cleanup

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

## Troubleshooting

### Common Issues

1. **AMI Missing Dependencies**

   ```bash
   # Verify AMI includes required packages
   # Build new AMI using the Packer module
   ```

2. **Network Connectivity**

   ```bash
   # Ensure outbound HTTPS (443) access to StackGuardian platform
   # Check VPC internet gateway and route tables
   ```

3. **API Key Issues**

   ```bash
   # Verify API key format (must start with 'sgu_')
   # Check API key permissions in StackGuardian console
   ```

4. **Scaling Not Working**
   ```bash
   # Check Lambda function logs in CloudWatch
   # Verify StackGuardian API connectivity from Lambda
   ```

### Debugging

```bash
# Enable detailed Terraform logging
export TF_LOG=DEBUG
terraform apply

# View Lambda function logs
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda"

# Check Auto Scaling Group activity
aws autoscaling describe-scaling-activities --auto-scaling-group-name <asg-name>
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

## Support

For issues and questions:

- Review the troubleshooting section above
- Check StackGuardian documentation
- Contact your StackGuardian support team

