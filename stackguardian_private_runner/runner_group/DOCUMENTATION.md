# StackGuardian Runner Group - AWS Template

Deploy a StackGuardian Runner Group with AWS S3 storage backend directly from the StackGuardian platform.

## Overview

This template sets up everything you need to run private runners in your AWS environment. It creates a runner group on the StackGuardian platform, provisions an S3 bucket for storing workflow artifacts, and configures secure access between StackGuardian and your AWS account.

### What This Template Creates

- **Runner Group** - A dedicated group in StackGuardian to organize your private runners
- **AWS Connector** - Secure integration between StackGuardian and your AWS account
- **S3 Storage Bucket** - Private storage for workflow outputs and artifacts
- **IAM Access Role** - Secure cross-account access for the StackGuardian platform

## Prerequisites

- A StackGuardian API key for your organization
- AWS account with permissions to create S3 buckets and IAM roles
- AWS credentials configured in your StackGuardian workspace

## Template Parameters

### Required Parameters

| Parameter | Description | Type |
|-----------|-------------|------|
| API Key | Your organization's API key on the StackGuardian Platform | Password |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| API Region | Select your StackGuardian platform region (EU1 or US1) | EU1 - Europe |
| Organization Name | Your organization name (auto-detected if not provided) | Auto-detected |
| AWS Region | The target AWS Region for S3 bucket and IAM resources | eu-central-1 |
| Create Storage Backend | Whether to create a new S3 bucket for the storage backend | Enabled |
| Existing S3 Bucket Name | Name of an existing S3 bucket (when not creating new bucket) | - |
| Force Destroy Storage Backend | Delete all data in S3 bucket when destroying (use with caution) | Disabled |
| Global Prefix | Prefix for naming all resources | SG_RUNNER |
| Include Organization Name in Prefix | Add org name to resource prefix for uniqueness | Disabled |
| Runner Group Name Override | Custom name for the runner group | Auto-generated |
| Connector Name Override | Custom name for the AWS connector | Auto-generated |
| Maximum Runners | Maximum number of runners allowed in the group | 3 |

## Important Notes

**API Key Security**: Your API key is stored securely and used only for authenticating with the StackGuardian platform. It must start with `sgu_` (user key) or `sgo_` (organization key).

**Storage Backend Options**: You can either create a new S3 bucket (recommended) or use an existing one. When using an existing bucket, ensure it has appropriate permissions.

**Resource Naming**: By default, resources are named using the pattern `SG_RUNNER-{type}-{aws_account_id}`. You can customize this using the naming options.

**Data Retention**: The `Force Destroy Storage Backend` option will delete all data when the template is destroyed. Leave this disabled to protect your data.

## Outputs

| Output | Description |
|--------|-------------|
| Runner Group Name | Name of the created runner group for use in workflow configurations |
| Runner Group Token | Authentication token for registering runners (keep secure) |
| Runner Group URL | Direct link to manage your runner group in the StackGuardian console |
| Connector Name | Name of the AWS connector integration |
| S3 Bucket Name | Name of the storage bucket for use with runner deployments |
| Storage Backend Role ARN | IAM role ARN required by runner EC2 instances |

## Security Features

- **Private S3 Storage**: Bucket is configured with public access blocked
- **Cross-Account Access**: Uses AWS IAM roles with external ID for secure access
- **Scoped Permissions**: IAM policies grant only necessary S3 operations
- **CORS Protection**: S3 bucket only allows requests from StackGuardian platform
- **Sensitive Output Protection**: Tokens and credentials are marked sensitive

## Usage

After deploying this template, use the outputs to:

1. **Deploy Runners**: Pass the `runner_group_name`, `runner_group_token`, `s3_bucket_name`, and `storage_backend_role_arn` to the AWS Autoscaled Runner or AWS Runner templates
2. **Configure Workflows**: Reference the runner group in your workflow configurations to execute jobs on private runners
3. **Monitor Runners**: Access the runner group URL to view runner status and manage the group
