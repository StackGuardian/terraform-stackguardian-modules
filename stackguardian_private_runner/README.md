# StackGuardian Private Runner

Deploy auto-scaling StackGuardian Private Runners on AWS with custom AMI creation.

## Overview

This template provides two modules that work together to create a complete private runner solution:

1. **[Packer Module](packer/)** - Build custom AMIs with pre-installed dependencies
2. **[AWS Module](aws/)** - Deploy auto-scaling private runners using the custom AMI

## Complete Deployment Guide

### Step 1: Build Custom AMI

Navigate to the **Packer** module and create an optimized AMI:

```bash
cd packer/
```

**Configure required variables:**

```hcl
aws_region = "eu-central-1"

network = {
  vpc_id           = "vpc-your-vpc-id"
  public_subnet_id = "subnet-your-subnet-id"
}
```

**Build the AMI:**

```bash
terraform init
terraform plan
terraform apply
```

**Save the AMI ID:**

```bash
# Note the output for Step 2
AMI_ID=$(terraform output -raw ami_id)
echo "AMI ID: $AMI_ID"
```

### Step 2: Deploy Private Runners

Navigate to the **AWS** module and deploy the infrastructure:

```bash
cd ../aws/
```

**Configure with your AMI:**

```hcl
ami_id     = "ami-your-ami-id"  # From Step 1
aws_region = "eu-central-1"

stackguardian = {
  api_key = "sgu_your_api_key_here"
}

network = {
  vpc_id           = "vpc-your-vpc-id"
  public_subnet_id = "subnet-your-subnet-id"
}
```

**Deploy the runners:**

```bash
terraform init
terraform plan
terraform apply
```

**Get the runner group name:**

```bash
# Use this in your StackGuardian workflows
terraform output runner_group_name
```

### Step 3: Configure Workflows

Use the runner group in your StackGuardian workflows:

```yaml
# In your StackGuardian workflow
runner_constraints:
  runner_group: <output from Step 2>
```

## What Gets Created

### Packer Module Output

- **Custom AMI**: Pre-configured with Docker, Terraform, OpenTofu, and sg-runner
- **Multi-OS Support**: Amazon Linux 2, Ubuntu LTS, and RHEL compatibility
- **Tool Installation**: Configurable versions of infrastructure tools
- **Optimization**: Faster job startup through pre-installation

### AWS Module Output

- **Auto Scaling Group**: EC2 instances with configurable scaling policies
- **Lambda Autoscaler**: Monitors StackGuardian job queues and triggers scaling
- **S3 Storage Backend**: Encrypted bucket for Terraform state with versioning
- **Security Configuration**: IAM roles and security groups with least-privilege access
- **StackGuardian Integration**: Runner Group and Connector for platform connectivity

## Prerequisites

Before starting, ensure you have:

1. **StackGuardian Account**: API key starting with `sgu_`
2. **AWS Account**: With sufficient permissions (see permission files below)
3. **Network Infrastructure**: Existing VPC with public subnet and internet gateway
4. **Local Tools**: Terraform >= 1.0 installed

### Required Permissions

- **Packer Build**: See `packer_permissions.json` for AMI creation permissions
- **AWS Deployment**: See `aws_permissions.json` for infrastructure deployment permissions

## Configuration Overview

### Required Configuration

Both modules require these common parameters:

| Parameter                  | Description       | Example             |
| -------------------------- | ----------------- | ------------------- |
| `aws_region`               | Target AWS region | `"eu-central-1"`    |
| `network.vpc_id`           | Existing VPC ID   | `"vpc-12345678"`    |
| `network.public_subnet_id` | Public subnet ID  | `"subnet-87654321"` |

### Module-Specific Configuration

**Packer Module:**

- `os.family` - Operating system (amazon/ubuntu/rhel)
- `terraform.primary_version` - Terraform version to install
- `packer_config.cleanup_amis_on_destroy` - AMI cleanup behavior

**AWS Module:**

- `stackguardian.api_key` - Your StackGuardian API key
- `ami_id` - Custom AMI from Packer module
- `autoscaler.max_instances` - Maximum runner instances

## Key Outputs

| Module | Output              | Description                | Usage                   |
| ------ | ------------------- | -------------------------- | ----------------------- |
| Packer | `ami_id`            | Created AMI identifier     | Input for AWS module    |
| AWS    | `runner_group_name` | StackGuardian runner group | Use in workflow configs |
| AWS    | `runner_group_url`  | Management console link    | Monitor and configure   |

## Architecture Benefits

- **Performance**: Pre-built AMI reduces job startup time by 60-80%
- **Scalability**: Auto-scaling based on job queue depth with configurable thresholds
- **Security**: Encrypted storage, least-privilege IAM, and configurable network access
- **Cost Management**: Scale to zero when idle, with automatic cleanup options
- **Reliability**: Multi-AZ deployment with health checks and auto-recovery

## Alternative Deployment Patterns

### Single Command Deployment

For automated deployments, use a script to deploy both modules:

```bash
#!/bin/bash
# Deploy complete private runner infrastructure

# Build AMI
cd packer/
terraform apply -auto-approve
AMI_ID=$(terraform output -raw ami_id)

# Deploy runners with AMI
cd ../aws/
terraform apply -auto-approve -var="ami_id=$AMI_ID"
```

### Module Composition

Use both modules in a single Terraform configuration:

```hcl
# Build AMI first
module "custom_ami" {
  source = "./packer"

  aws_region = var.aws_region
  network    = var.network
  os         = var.os_config
}

# Deploy runners with the AMI
module "private_runners" {
  source = "./aws"

  ami_id        = module.custom_ami.ami_id
  aws_region    = var.aws_region
  stackguardian = var.stackguardian
  network       = var.network

  depends_on = [module.custom_ami]
}
```
