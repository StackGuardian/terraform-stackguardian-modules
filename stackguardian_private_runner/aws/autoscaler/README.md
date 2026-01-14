# StackGuardian Runner Autoscaler - AWS Module

This Terraform module deploys a Lambda-based autoscaler that monitors StackGuardian job queues and automatically scales an Auto Scaling Group up or down based on workload demand.

## Overview

The autoscaler module provides intelligent scaling for StackGuardian Private Runners by monitoring job queue depth and adjusting the number of runner instances accordingly. It runs as a serverless Lambda function triggered every minute by EventBridge Scheduler.

### What Gets Created

- **Lambda Function**: Python-based autoscaler that queries StackGuardian API for queue status
- **EventBridge Scheduler**: Triggers the Lambda function every minute
- **IAM Roles & Policies**: Execution roles for Lambda and EventBridge Scheduler
- **CloudWatch Log Group**: Stores Lambda execution logs with 14-day retention

## Prerequisites

Before deploying this module, you need:

1. **StackGuardian Runner Group** - Deploy the `runner_group` module first to get:
   - `runner_group_name`
   - `s3_bucket_name`

2. **Auto Scaling Group** - Deploy the `autoscaling_group` module to get:
   - `asg_name` (Auto Scaling Group name)

3. **StackGuardian API Key** - Organization API key (`sgu_*` or `sgo_*`) from the StackGuardian platform

4. **AWS Permissions** - IAM permissions to create Lambda, IAM roles, EventBridge Scheduler, and CloudWatch resources

## Quick Start

### Step 1: Deploy Prerequisites

First, deploy the runner group and autoscaling group modules:

```bash
# Deploy runner group
cd ../runner_group
terraform apply

# Deploy autoscaling group
cd ../autoscaling_group
terraform apply
```

### Step 2: Deploy Autoscaler

```bash
cd autoscaler
terraform init
terraform apply
```

### Basic Configuration Example

```hcl
module "autoscaler" {
  source = "./autoscaler"

  aws_region        = "eu-central-1"
  asg_name          = module.autoscaling_group.autoscaling_group_name
  runner_group_name = module.runner_group.runner_group_name
  s3_bucket_name    = module.runner_group.s3_bucket_name

  stackguardian = {
    api_key  = var.sg_api_key
    org_name = "my-org"
  }
}
```

## Configuration

### Required Parameters

| Parameter | Description | Type |
|-----------|-------------|------|
| `stackguardian` | StackGuardian platform configuration (see nested parameters below) | `object` |
| `stackguardian.api_key` | StackGuardian API key (`sgu_*` or `sgo_*`) | `string` |
| `asg_name` | Name of the Auto Scaling Group to scale (from autoscaling_group module) | `string` |
| `runner_group_name` | Name of the StackGuardian runner group (from runner_group module) | `string` |
| `s3_bucket_name` | Name of the S3 bucket for storage backend (from runner_group module) | `string` |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `stackguardian.api_uri` | StackGuardian API endpoint (EU1, US1, or DASH) | `https://api.app.stackguardian.io` |
| `stackguardian.org_name` | Organization name (extracted from environment if not provided) | `""` |
| `runner_type` | Runner type: `external` or `shared-external` | `external` |
| `aws_region` | AWS region for deployment | `eu-central-1` |
| `override_names.global_prefix` | Prefix for resource naming | `SG_RUNNER` |
| `override_names.include_org_in_prefix` | Append org name to prefix | `false` |
| `scaling.min_size` | Minimum number of runners | `1` |
| `scaling.scale_out_threshold` | Queued jobs to trigger scale-out | `3` |
| `scaling.scale_in_threshold` | Queued jobs to trigger scale-in | `1` |
| `scaling.scale_out_step` | Instances to add when scaling out | `1` |
| `scaling.scale_in_step` | Instances to remove when scaling in | `1` |
| `scaling.scale_out_cooldown_duration` | Minutes after scale-out before scaling again (min: 4) | `4` |
| `scaling.scale_in_cooldown_duration` | Minutes after scale-in before scaling again | `5` |
| `lambda_config.runtime` | Python runtime version | `python3.11` |
| `lambda_config.timeout` | Lambda timeout in seconds | `60` |
| `lambda_config.memory_size` | Lambda memory in MB | `128` |
| `autoscaler_repo.url` | Git repository URL for Lambda source | `https://github.com/StackGuardian/sg-runner-autoscaler` |
| `autoscaler_repo.branch` | Git branch for Lambda source | `main` |

### Configuration Examples

#### Basic Configuration

```hcl
module "autoscaler" {
  source = "./autoscaler"

  asg_name          = module.autoscaling_group.autoscaling_group_name
  runner_group_name = module.runner_group.runner_group_name
  s3_bucket_name    = module.runner_group.s3_bucket_name

  stackguardian = {
    api_key = var.sg_api_key
  }
}
```

#### Advanced Configuration

```hcl
module "autoscaler" {
  source = "./autoscaler"

  aws_region        = "us-east-1"
  runner_type       = "external"
  asg_name          = module.autoscaling_group.autoscaling_group_name
  runner_group_name = module.runner_group.runner_group_name
  s3_bucket_name    = module.runner_group.s3_bucket_name

  stackguardian = {
    api_key  = var.sg_api_key
    api_uri  = "https://api.us.stackguardian.io"
    org_name = "my-org"
  }

  override_names = {
    global_prefix         = "PROD_RUNNER"
    include_org_in_prefix = true
  }

  scaling = {
    min_size                    = 2
    scale_out_threshold         = 5
    scale_in_threshold          = 2
    scale_out_step              = 2
    scale_in_step               = 1
    scale_out_cooldown_duration = 5
    scale_in_cooldown_duration  = 10
  }

  lambda_config = {
    runtime     = "python3.12"
    timeout     = 120
    memory_size = 256
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

# Preview changes
terraform plan

# Apply configuration
terraform apply
```

### Auto-scaling Behavior

The autoscaler operates on a 1-minute cycle:

1. **Scale-out**: When queued jobs >= `scale_out_threshold`, adds `scale_out_step` instances
2. **Scale-in**: When queued jobs < `scale_in_threshold`, removes `scale_in_step` instances (down to `min_size`)
3. **Cooldown**: After scaling, waits the configured cooldown duration before scaling again

Default behavior:
- Scales out when 3+ jobs are queued
- Scales in when fewer than 2 jobs are queued
- 4-minute cooldown after scale-out
- 5-minute cooldown after scale-in

### Cleanup

```bash
# Destroy the autoscaler
terraform destroy
```

## Architecture

### Resource Organization

| File | Contents |
|------|----------|
| `provider.tf` | AWS, null, archive, external provider configuration |
| `variables.tf` | Input variable definitions and validations |
| `locals.tf` | Computed values and naming conventions |
| `lambda.tf` | Lambda function and CloudWatch log group |
| `lambda_build.tf` | Lambda package build from Git repository |
| `iam.tf` | IAM roles and policies for Lambda and Scheduler |
| `scheduler.tf` | EventBridge Scheduler configuration |
| `outputs.tf` | Module outputs |

### Resource Naming Convention

Resources are named using the pattern: `{global_prefix}[-{org_name}]-{resource-type}`

Examples with default prefix `SG_RUNNER`:
- Lambda: `SG_RUNNER-autoscale-private-runner`
- Scheduler: `SG_RUNNER-autoscale-trigger`
- IAM Role: `SG_RUNNER-autoscale-lambda-role`

With `include_org_in_prefix = true` and `org_name = "demo"`:
- Lambda: `SG_RUNNER_demo-autoscale-private-runner`

## Troubleshooting

### Common Issues

1. **Lambda fails to scale ASG**
   - Verify the `asg_name` matches the actual Auto Scaling Group name
   - Check IAM permissions for `autoscaling:SetDesiredCapacity`

2. **API authentication errors**
   - Verify the `api_key` is valid and starts with `sgu_` or `sgo_`
   - Ensure `org_name` matches your StackGuardian organization

3. **Build failures**
   - Ensure `git` is installed for cloning the autoscaler repository
   - Ensure `pip` is available for installing Python dependencies

### Debugging Commands

```bash
# View Lambda logs
aws logs tail /aws/lambda/{prefix}-autoscale-private-runner --follow

# Check Lambda function status
aws lambda get-function --function-name {prefix}-autoscale-private-runner

# View EventBridge Scheduler
aws scheduler get-schedule --name {prefix}-autoscale-trigger --group-name default

# Check ASG current state
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names {asg_name}
```

## Outputs

| Output | Description |
|--------|-------------|
| `lambda_function_name` | The name of the Lambda autoscaler function |
| `lambda_function_arn` | The ARN of the Lambda autoscaler function |
| `lambda_role_arn` | The ARN of the Lambda execution role |
| `scheduler_arn` | The ARN of the EventBridge Scheduler |
| `scheduler_name` | The name of the EventBridge Scheduler |
| `log_group_name` | The name of the CloudWatch Log Group |

## Security Considerations

- **API Key Protection**: The StackGuardian API key is stored as a Lambda environment variable (encrypted at rest)
- **IAM Least Privilege**: Lambda role has minimal permissions for S3, ASG, EC2, and CloudWatch
- **Network Security**: Lambda runs in AWS-managed VPC (no customer VPC configuration required)
- **Log Retention**: CloudWatch logs are retained for 14 days

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 4.0 |
| null | >= 3.0 |
| archive | >= 2.0 |
| external | >= 2.0 |

## Next Steps

After deployment:

1. Monitor Lambda logs for scaling events
2. Adjust scaling thresholds based on workload patterns
3. Review CloudWatch metrics for Lambda invocations and errors

## Support

- [StackGuardian Documentation](https://docs.stackguardian.io)
- [GitHub Issues](https://github.com/StackGuardian/terraform-stackguardian-modules/issues)
