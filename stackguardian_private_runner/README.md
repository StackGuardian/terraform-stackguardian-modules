# StackGuardian Private Runner

Deploy auto-scaling StackGuardian Private Runners on AWS or Azure.

> **Just want a runner running?** [`examples/aws/quickstart/`](examples/aws/quickstart/)
> wires the runner group, AMI build, and a single runner into one root module. Fill in
> four values, apply once, and you have a registered runner - no copying outputs
> between modules.

## Overview

This project provides Terraform modules that work together to create a complete auto-scaling private runner solution on AWS or Azure.

### AWS

1. **[Packer AMI Builder](aws/packer/)** - Build custom AMIs with pre-installed dependencies
2. **[Runner Group](aws/runner_group/)** - Create StackGuardian Runner Group with S3 storage backend
3. **[Autoscaling Group](aws/autoscaling_group/)** - Deploy auto-scaling EC2 runner instances
4. **[Autoscaler](aws/autoscaler/)** - Lambda-based intelligent scaling based on job queue

**Alternative**: For simpler deployments without auto-scaling, see [Single Runner](aws/single_runner/), or the ready-made [AWS Quickstart example](examples/aws/quickstart/) that deploys one end to end.

### Azure

1. **[Packer Image Builder](azure/packer/)** - Build custom Azure Managed Images with pre-installed dependencies
2. **[Runner Group](azure/runner_group/)** - Create StackGuardian Runner Group with Azure Blob Storage backend
3. **[Single Runner](azure/azure_runner/)** - Deploy a standalone runner on an Azure Linux VM
4. **[Autoscaler](azure/autoscaler/)** - Azure Function-based intelligent scaling for VM Scale Sets

## AWS Deployment Guide

### Step 1: Build Custom AMI

Navigate to the **Packer** module and create an optimized AMI.

```bash
cd aws/packer/
```

See [aws/packer/README.md](aws/packer/README.md) for full configuration options.

> **AMI reuse:** Packer runs on the first apply only. The AMI ID is recorded in
> state and reused by every later plan, so re-applies are fast and the runner keeps
> the same image. To build a fresh AMI, change `packer_config.rebuild_ami_token` to
> any new value. See [When Packer Runs](aws/packer/README.md#when-packer-runs).

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
cd ../aws/runner_group/
# Or from root: cd aws/runner_group/
```

See [aws/runner_group/README.md](aws/runner_group/README.md) for full configuration options.

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
cd ../autoscaling_group/
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

### AWS Modules

Stack overview: [aws/DOCUMENTATION.md](aws/DOCUMENTATION.md)

| Module | Purpose | Configuration |
|--------|---------|---------------|
| [aws/packer](aws/packer/) | Build custom AMI | [README](aws/packer/README.md) |
| [aws/runner_group](aws/runner_group/) | Create Runner Group and S3 backend | [README](aws/runner_group/README.md) |
| [aws/single_runner](aws/single_runner/) | Deploy one EC2 runner (no autoscaling) | [README](aws/single_runner/README.md) |
| [aws/autoscaling_group](aws/autoscaling_group/) | Deploy EC2 Auto Scaling Group | [README](aws/autoscaling_group/README.md) |
| [aws/autoscaler](aws/autoscaler/) | Deploy Lambda autoscaler | [README](aws/autoscaler/README.md) |

### Azure Modules

Stack overview: [azure/DOCUMENTATION.md](azure/DOCUMENTATION.md)

| Module | Purpose | Configuration |
|--------|---------|---------------|
| [azure/packer](azure/packer/) | Build custom Azure Managed Image | [README](azure/packer/README.md) |
| [azure/runner_group](azure/runner_group/) | Create Runner Group and Blob Storage backend | [README](azure/runner_group/README.md) |
| [azure/azure_runner](azure/azure_runner/) | Deploy Azure Linux VM runner | [README](azure/azure_runner/README.md) |
| [azure/vmss](azure/vmss/) | Deploy Azure VM Scale Set of runners | [README](azure/vmss/README.md) |
| [azure/autoscaler](azure/autoscaler/) | Deploy Azure Function autoscaler | [README](azure/autoscaler/README.md) |

### Shared

| Module | Purpose | Configuration |
|--------|---------|---------------|
| [runner_group](runner_group/) | Cloud-agnostic platform resources, called by both `*/runner_group` wrappers. Not deployed directly. | [README](runner_group/README.md) |

### Examples

| Example | Purpose |
|---------|---------|
| [examples/aws/quickstart](examples/aws/quickstart/) | Runner group + AMI build + one EC2 runner in a single apply |
| [examples/azure/quickstart](examples/azure/quickstart/) | Runner group + image build + one Azure VM runner in a single apply |
| [examples/aws/packer](examples/aws/packer/) | Just the AMI build — bake an image once and reuse its `ami_id` |
| [examples/azure/packer](examples/azure/packer/) | Just the image build — bake an image once and reuse its `image_id` |

### Common Required Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `aws_region` / `azure_location` | Target cloud region | `"eu-central-1"` / `"westeurope"` |
| `stackguardian.api_key` | StackGuardian API key | `"sgu_..."` |
| `network.vpc_id` / `network.vnet_id` | Existing network ID | `"vpc-12345678"` / `"/subscriptions/..."` |

## Key Outputs

### AWS Outputs

| Template | Output | Description | Usage |
|----------|--------|-------------|-------|
| Packer | `ami_id` | Built AMI identifier, recorded in state | Input for Autoscaling Group |
| Runner Group | `runner_group_name` | StackGuardian runner group name | Input for ASG and Autoscaler |
| Runner Group | `runner_group_token` | Token for runner registration | Input for Autoscaling Group |
| Runner Group | `s3_bucket_name` | S3 storage backend bucket | Input for ASG and Autoscaler |
| Autoscaling Group | `autoscaling_group_name` | ASG name | Input for Autoscaler |
| Autoscaler | `lambda_function_name` | Lambda function name | Monitoring |

### Azure Outputs

| Template | Output | Description | Usage |
|----------|--------|-------------|-------|
| Packer | `image_id` | Created Azure Managed Image ID | Input for Azure Runner |
| Azure Runner | `vm_id` | Azure VM identifier | Monitoring |
| Azure Runner | `vm_private_ip` | Runner private IP address | Connectivity |
| Autoscaler | `function_app_name` | Azure Function App name | Monitoring |
| Autoscaler | `storage_account_name` | Storage Account name | Monitoring |

## Architecture Benefits

- **Performance**: Pre-built images reduce job startup time by 60-80%
- **Scalability**: Auto-scaling based on job queue depth with configurable thresholds
- **Security**: Encrypted storage, least-privilege access, and configurable network access
- **Cost Management**: Scale to zero when idle, with automatic cleanup options
- **Reliability**: Health checks and auto-recovery across both cloud providers

## Alternative: Single Runner

For simpler deployments without auto-scaling:

- **AWS**: Use the [AWS Single Runner](aws/single_runner/) module. See [README](aws/single_runner/README.md).
- **Azure**: Use the [Azure Single Runner](azure/azure_runner/) module. See [README](azure/azure_runner/README.md).

**When to use:**

- Development and testing environments
- Low-volume workflow execution
- Simpler infrastructure requirements

For AWS, the fastest path is [`examples/aws/quickstart/`](examples/aws/quickstart/), a root
module that combines the runner group, AMI build, and single runner into one apply.
Use the `aws/single_runner` module directly instead when you need a private subnet,
NAT gateway, or proxy - the quickstart deliberately covers the public-subnet case only.

## Automated Deployment

### AWS

For automated AWS deployments, use a script to deploy all modules:

```bash
#!/bin/bash
# Deploy complete private runner infrastructure (AWS)

set -e

# Step 1: Build AMI
cd aws/packer/
terraform init && terraform apply -auto-approve
AMI_ID=$(terraform output -raw ami_id)

# Step 2: Create Runner Group
cd ../runner_group/
terraform init && terraform apply -auto-approve
RUNNER_GROUP_NAME=$(terraform output -raw runner_group_name)
RUNNER_GROUP_TOKEN=$(terraform output -raw runner_group_token)
S3_BUCKET_NAME=$(terraform output -raw s3_bucket_name)
STORAGE_ROLE_ARN=$(terraform output -raw storage_backend_role_arn)

# Step 3: Deploy Autoscaling Group
cd ../autoscaling_group/
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

echo "AWS Deployment complete!"
echo "Runner Group: $RUNNER_GROUP_NAME"
```

### Azure

For automated Azure deployments:

```bash
#!/bin/bash
# Deploy complete private runner infrastructure (Azure)

set -e

# Step 1: Build Custom Image
cd azure/packer/
terraform init && terraform apply -auto-approve
IMAGE_ID=$(terraform output -raw image_id)

# Step 2: Create Runner Group
cd ../runner_group/
terraform init && terraform apply -auto-approve
RUNNER_GROUP_NAME=$(terraform output -raw runner_group_name)
RUNNER_GROUP_TOKEN=$(terraform output -raw runner_group_token)
RESOURCE_GROUP_NAME=$(terraform output -raw azure_resource_group_name)

# Step 3: Deploy Azure Runner
#   storage_backend_identity_id is a User-Assigned Managed Identity you create
#   yourself and grant "Storage Blob Data Contributor" on the storage account;
#   see examples/azure/quickstart for a worked version.
cd ../azure_runner/
terraform init
terraform apply -auto-approve \
  -var="vm_image_id=$IMAGE_ID" \
  -var="runner_group_name=$RUNNER_GROUP_NAME" \
  -var="runner_group_token=$RUNNER_GROUP_TOKEN" \
  -var="storage_backend_identity_id=$STORAGE_BACKEND_IDENTITY_ID"

# Step 4: Deploy Autoscaler
cd ../autoscaler/
terraform init
terraform apply -auto-approve

echo "Azure Deployment complete!"
echo "Runner Group: $RUNNER_GROUP_NAME"
```

---

## Azure Deployment Guide

### Prerequisites

Before starting Azure deployment, ensure you have:

1. **StackGuardian Account**: API key (`sgo_*` or `sgu_*`)
2. **Azure Subscription**: With Contributor permissions
3. **Azure CLI**: Authenticated (`az login`)
4. **Network Infrastructure**: Existing VNet with subnet and internet access (or let modules create new ones)
5. **Local Tools**: Terraform >= 1.0 installed

### Step 1: Build Custom Image

Navigate to the **Packer** module and create an optimized Azure Managed Image.

```bash
cd azure/packer/
```

See [azure/packer/README.md](azure/packer/README.md) for full configuration options.

**Deploy:**

```bash
terraform init
terraform plan
terraform apply
```

**Save outputs for Step 3:**

```bash
IMAGE_ID=$(terraform output -raw image_id)
echo "Image ID: $IMAGE_ID"
```

### Step 2: Create Runner Group

Navigate to the **Runner Group** module and create the StackGuardian runner group.

```bash
cd ../runner_group/
# Or from root: cd azure/runner_group/
```

See [azure/runner_group/README.md](azure/runner_group/README.md) for full configuration options.

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
RESOURCE_GROUP_NAME=$(terraform output -raw azure_resource_group_name)
STORAGE_ACCOUNT_ID=$(terraform output -raw azure_storage_account_id)
```

### Step 3: Deploy Azure Runner

Navigate to the **Azure Runner** module and deploy the runner VM.

```bash
cd ../azure_runner/
# Or from root: cd azure/azure_runner/
```

See [azure/azure_runner/README.md](azure/azure_runner/README.md) for full configuration options.

**Configure with outputs from Steps 1 and 2:**

```hcl
vm_image_id                 = "/subscriptions/.../images/sg-runner-ubuntu"  # From Step 1
runner_group_name           = "your-runner-group"  # From Step 2
runner_group_token          = "your-token"  # From Step 2
storage_backend_identity_id = "/subscriptions/.../userAssignedIdentities/..."  # See note below
```

> **Managed identity:** the runner group module does not create the identity the VM
> uses to reach the storage account. Create a User-Assigned Managed Identity and grant it
> `Storage Blob Data Contributor` scoped to `azure_storage_account_id` from Step 2 — see
> [examples/azure/quickstart](examples/azure/quickstart/) for a worked version.

**Deploy:**

```bash
terraform init
terraform plan
terraform apply
```

### Step 4: Deploy Azure Autoscaler

Navigate to the **Autoscaler** module and deploy intelligent scaling.

```bash
cd ../autoscaler/
# Or from root: cd azure/autoscaler/
```

See [azure/autoscaler/README.md](azure/autoscaler/README.md) for full configuration options, including manual Azure CLI setup.

**Configure with outputs from Step 2:**

```hcl
resource_group_name = "my-resource-group"
azure_location      = "westeurope"

vmss = {
  name                = "my-runner-vmss"
  resource_group_name = "vmss-resource-group"
}

stackguardian = {
  api_key  = "sgu_xxxxxxxxxxxx"
  org_name = "my-org"
}

override_names = {
  global_prefix     = "sg-runner"
  runner_group_name = "your-runner-group"  # From Step 2
}
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

### What Gets Created (Azure)

#### Packer Image Builder

- **Azure Managed Image**: Pre-configured with Docker, Terraform, OpenTofu, and sg-runner
- **Multi-OS Support**: Ubuntu LTS and RHEL compatibility
- **Tool Installation**: Configurable versions of infrastructure tools

#### Azure Runner

- **Linux Virtual Machine**: Runner instance with configurable size and storage
- **Network Security Group**: Configurable inbound rules with full outbound access
- **SSH Key Pair**: Auto-generated or user-provided
- **Network Infrastructure**: Optional VNet and subnet creation

#### Azure Autoscaler

- **Function App**: FlexConsumption plan with Python 3.11 runtime
- **Storage Account**: For function state and autoscaler timestamps
- **Application Insights**: Monitoring and logging
- **Role Assignments**: Managed identity with VMSS and storage access
