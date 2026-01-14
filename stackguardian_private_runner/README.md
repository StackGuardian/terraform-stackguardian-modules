# StackGuardian Private Runner

Deploy auto-scaling StackGuardian Private Runners on AWS with custom AMI creation.

## Overview

This project provides four templates that work together to create a complete auto-scaling private runner solution:

1. **[Packer AMI Builder](aws/packer/)** - Build custom AMIs with pre-installed dependencies
2. **[Runner Group](runner_group/)** - Create StackGuardian Runner Group with S3 storage backend
3. **[Autoscaling Group](aws/autoscaling_group/)** - Deploy auto-scaling EC2 runner instances
4. **[Autoscaler](aws/autoscaler/)** - Lambda-based intelligent scaling based on job queue

**Alternative**: For simpler deployments without auto-scaling, see [Single Runner](aws/single_runner/).

## Complete Deployment Guide

### Step 1: Build Custom AMI

Navigate to the **Packer** module and create an optimized AMI.

```bash
cd aws/packer/
```

See [aws/packer/README.md](aws/packer/README.md) for full configuration options.

**Deploy:**

```bash
terraform init
terraform plan
terraform apply
```

**Save outputs for Step 3:**

```bash
AMI_ID=$(terraform output -raw ami_id)
echo "AMI ID: $AMI_ID"
```

### Step 2: Create Runner Group

Navigate to the **Runner Group** module and create the StackGuardian runner group with S3 backend.

```bash
cd ../runner_group/
# Or from root: cd runner_group/
```

See [runner_group/README.md](runner_group/README.md) for full configuration options.

**Deploy:**

```bash
terraform init
terraform plan
terraform apply
```

**Save outputs for Steps 3 and 4:**

```bash
RUNNER_GROUP_NAME=$(terraform output -raw runner_group_name)
RUNNER_GROUP_TOKEN=$(terraform output -raw runner_group_token)
S3_BUCKET_NAME=$(terraform output -raw s3_bucket_name)
STORAGE_ROLE_ARN=$(terraform output -raw storage_backend_role_arn)
```

### Step 3: Deploy Autoscaling Group

Navigate to the **Autoscaling Group** module and deploy EC2 runner instances.

```bash
cd ../aws/autoscaling_group/
# Or from root: cd aws/autoscaling_group/
```

See [aws/autoscaling_group/README.md](aws/autoscaling_group/README.md) for full configuration options.

**Configure with outputs from Steps 1 and 2:**

```hcl
ami_id                   = "ami-your-ami-id"  # From Step 1
runner_group_name        = "your-runner-group"  # From Step 2
runner_group_token       = "your-token"  # From Step 2
s3_bucket_name           = "your-bucket"  # From Step 2
storage_backend_role_arn = "arn:aws:iam::..."  # From Step 2
```

**Deploy:**

```bash
terraform init
terraform plan
terraform apply
```

**Save outputs for Step 4:**

```bash
ASG_NAME=$(terraform output -raw autoscaling_group_name)
```

### Step 4: Deploy Lambda Autoscaler

Navigate to the **Autoscaler** module and deploy intelligent scaling.

```bash
cd ../autoscaler/
# Or from root: cd aws/autoscaler/
```

See [aws/autoscaler/README.md](aws/autoscaler/README.md) for full configuration options.

**Configure with outputs from Steps 2 and 3:**

```hcl
asg_name          = "your-asg-name"  # From Step 3
runner_group_name = "your-runner-group"  # From Step 2
s3_bucket_name    = "your-bucket"  # From Step 2
```

**Deploy:**

```bash
terraform init
terraform plan
terraform apply
```

### Step 5: Configure Workflows

Use the runner group in your StackGuardian workflows:

```yaml
# In your StackGuardian workflow
runner_constraints:
  runner_group: <runner_group_name from Step 2>
```

## What Gets Created

### Packer AMI Builder

- **Custom AMI**: Pre-configured with Docker, Terraform, OpenTofu, and sg-runner
- **Multi-OS Support**: Amazon Linux 2, Ubuntu LTS, and RHEL compatibility
- **Tool Installation**: Configurable versions of infrastructure tools

### Runner Group

- **StackGuardian Runner Group**: Platform integration for runner management
- **S3 Storage Backend**: Encrypted bucket for Terraform state with versioning
- **AWS Connector**: Cross-account access configuration

### Autoscaling Group

- **Auto Scaling Group**: EC2 instances with configurable scaling
- **Launch Template**: Instance configuration with custom AMI
- **IAM Roles**: EC2 instance roles with least-privilege access
- **Security Groups**: Network access controls
- **Network Infrastructure**: Optional NAT Gateway for private deployments

### Autoscaler

- **Lambda Function**: Monitors job queues and triggers scaling
- **EventBridge Scheduler**: Periodic invocation of scaling logic
- **CloudWatch Logs**: Monitoring and debugging

## Prerequisites

Before starting, ensure you have:

1. **StackGuardian Account**: API key (`sgo_*` or `sgu_*`)
2. **AWS Account**: With sufficient permissions (see permission files below)
3. **Network Infrastructure**: Existing VPC with subnets and internet access
4. **Local Tools**: Terraform >= 1.0 installed

### Required Permissions

- **Packer Build**: See `packer_permissions.json` for AMI creation permissions
- **AWS Deployment**: See `aws_permissions.json` for infrastructure deployment permissions

## Module Configuration

Each module has its own README with detailed configuration options:

| Module | Purpose | Configuration |
|--------|---------|---------------|
| [aws/packer](aws/packer/) | Build custom AMI | [README](aws/packer/README.md) |
| [runner_group](runner_group/) | Create Runner Group and S3 backend | [README](runner_group/README.md) |
| [aws/autoscaling_group](aws/autoscaling_group/) | Deploy EC2 Auto Scaling Group | [README](aws/autoscaling_group/README.md) |
| [aws/autoscaler](aws/autoscaler/) | Deploy Lambda autoscaler | [README](aws/autoscaler/README.md) |

### Common Required Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `aws_region` | Target AWS region | `"eu-central-1"` |
| `stackguardian.api_key` | StackGuardian API key | `"sgu_..."` |
| `network.vpc_id` | Existing VPC ID | `"vpc-12345678"` |

## Key Outputs

| Template | Output | Description | Usage |
|----------|--------|-------------|-------|
| Packer | `ami_id` | Created AMI identifier | Input for Autoscaling Group |
| Runner Group | `runner_group_name` | StackGuardian runner group name | Input for ASG and Autoscaler |
| Runner Group | `runner_group_token` | Token for runner registration | Input for Autoscaling Group |
| Runner Group | `s3_bucket_name` | S3 storage backend bucket | Input for ASG and Autoscaler |
| Autoscaling Group | `autoscaling_group_name` | ASG name | Input for Autoscaler |
| Autoscaler | `lambda_function_name` | Lambda function name | Monitoring |

## Architecture Benefits

- **Performance**: Pre-built AMI reduces job startup time by 60-80%
- **Scalability**: Auto-scaling based on job queue depth with configurable thresholds
- **Security**: Encrypted storage, least-privilege IAM, and configurable network access
- **Cost Management**: Scale to zero when idle, with automatic cleanup options
- **Reliability**: Multi-AZ deployment with health checks and auto-recovery

## Alternative: Single Runner

For simpler deployments without auto-scaling, use the [Single Runner](aws/single_runner/) module.

**When to use:**

- Development and testing environments
- Low-volume workflow execution
- Simpler infrastructure requirements

See [aws/single_runner/README.md](aws/single_runner/README.md) for configuration.

## Automated Deployment

For automated deployments, use a script to deploy all modules:

```bash
#!/bin/bash
# Deploy complete private runner infrastructure

set -e

# Step 1: Build AMI
cd aws/packer/
terraform init && terraform apply -auto-approve
AMI_ID=$(terraform output -raw ami_id)

# Step 2: Create Runner Group
cd ../../runner_group/
terraform init && terraform apply -auto-approve
RUNNER_GROUP_NAME=$(terraform output -raw runner_group_name)
RUNNER_GROUP_TOKEN=$(terraform output -raw runner_group_token)
S3_BUCKET_NAME=$(terraform output -raw s3_bucket_name)
STORAGE_ROLE_ARN=$(terraform output -raw storage_backend_role_arn)

# Step 3: Deploy Autoscaling Group
cd ../aws/autoscaling_group/
terraform init
terraform apply -auto-approve \
  -var="ami_id=$AMI_ID" \
  -var="runner_group_name=$RUNNER_GROUP_NAME" \
  -var="runner_group_token=$RUNNER_GROUP_TOKEN" \
  -var="s3_bucket_name=$S3_BUCKET_NAME" \
  -var="storage_backend_role_arn=$STORAGE_ROLE_ARN"
ASG_NAME=$(terraform output -raw autoscaling_group_name)

# Step 4: Deploy Autoscaler
cd ../autoscaler/
terraform init
terraform apply -auto-approve \
  -var="asg_name=$ASG_NAME" \
  -var="runner_group_name=$RUNNER_GROUP_NAME" \
  -var="s3_bucket_name=$S3_BUCKET_NAME"

echo "Deployment complete!"
echo "Runner Group: $RUNNER_GROUP_NAME"
```
