# StackGuardian Runner Autoscaler - AWS Template

Deploy a Lambda-based autoscaler that monitors StackGuardian job queues and scales the Auto Scaling Group up or down based on workload demand.

## Overview

This template creates an intelligent autoscaling system that monitors your StackGuardian job queues and automatically adjusts the number of runner instances based on workload demand. When jobs are queued, more runners are added; when the queue is empty, runners are removed to reduce costs.

### What This Template Creates

- **Lambda Function** that checks job queue status every minute and scales runners accordingly
- **EventBridge Scheduler** that triggers the scaling check on a regular interval
- **IAM Roles** with permissions to manage Auto Scaling Groups and access S3
- **CloudWatch Logs** for monitoring and troubleshooting

## Prerequisites

Before using this template, you need:

1. **Runner Group** - Deploy the "StackGuardian Runner Group" template first
2. **Auto Scaling Group** - Deploy the "StackGuardian Autoscaling Group" template
3. **StackGuardian API Key** - Available from your organization settings
4. **AWS Permissions** - Permissions to create Lambda, IAM, EventBridge, and CloudWatch resources

## Template Parameters

### Required Parameters

| Parameter | Description | Type |
|-----------|-------------|------|
| API Key | Your organization's API key (sgo_*/sgu_*) or a secret reference (${secret::SECRET_NAME}) | String |
| Auto Scaling Group Name | The name of the Auto Scaling Group to scale (output from autoscaling_group module) | String |
| Runner Group Name | The name of the StackGuardian runner group (output from runner_group module) | String |
| S3 Bucket Name | The name of the S3 bucket for storage backend (output from runner_group module) | String |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| API Region | Select your StackGuardian platform region | EU1 - Europe |
| Organization Name | Your organization name on the StackGuardian Platform | (extracted from environment) |
| Runner Type | Select the type of StackGuardian runner | External (Private Runners) |
| AWS Region | The target AWS Region to deploy the autoscaler Lambda function | eu-central-1 |
| Global Prefix | Prefix for naming all resources created by this module | SG_RUNNER |
| Include Org in Prefix | When enabled, appends organization name to the global prefix | Disabled |
| Minimum Runners | Minimum number of runners to maintain | 1 |
| Scale Out Threshold | Number of queued jobs to trigger scale-out | 3 |
| Scale In Threshold | Number of queued jobs below which to trigger scale-in | 1 |
| Scale Out Step | Number of instances to add when scaling out | 1 |
| Scale In Step | Number of instances to remove when scaling in | 1 |
| Scale Out Cooldown (minutes) | Minutes to wait after scale-out before scaling again (minimum: 4) | 4 |
| Scale In Cooldown (minutes) | Minutes to wait after scale-in before scaling again | 5 |
| Python Runtime | Python runtime version for the Lambda function | python3.11 |
| Timeout (seconds) | Timeout in seconds for the Lambda function | 60 |
| Memory Size (MB) | Memory size in MB for the Lambda function | 128 |
| Repository URL | Git repository URL containing the autoscaler Lambda source code | https://github.com/StackGuardian/sg-runner-autoscaler |
| Branch | Git branch to use for the autoscaler Lambda source code | main |

## Important Notes

**Scaling Behavior**: The autoscaler checks your job queue every minute. When more than 3 jobs are queued (default), it adds runners. When fewer than 2 jobs are queued, it removes runners down to the minimum size. Cooldown periods prevent rapid scaling fluctuations.

**Dependencies**: This template requires outputs from the Runner Group and Autoscaling Group templates. Deploy those first and use their outputs as inputs to this template.

**Cost Optimization**: The autoscaler helps reduce costs by automatically scaling down when runners are not needed. Adjust the minimum runners and thresholds based on your workload patterns.

**Runner Types**: Choose "External" for private runners or "Shared External" for managed shared runners. This determines which queue metric is used for scaling decisions.

## Outputs

| Output | Description |
|--------|-------------|
| Lambda Function Name | The name of the autoscaler Lambda function |
| Lambda Function ARN | The ARN for referencing the Lambda function |
| Scheduler Name | The name of the EventBridge Scheduler |
| Log Group Name | CloudWatch Log Group for viewing autoscaler logs |

## Security Features

- API keys are stored securely as Lambda environment variables (encrypted at rest)
- IAM roles follow the principle of least privilege
- CloudWatch logs are retained for 14 days for audit purposes
- No customer VPC configuration required - Lambda runs in AWS-managed infrastructure
