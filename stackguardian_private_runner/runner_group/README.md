# StackGuardian Runner Group - AWS Module

This Terraform module creates a StackGuardian Runner Group with S3 storage backend and AWS connector integration for running private runners in your AWS environment.

## Overview

The module provisions all necessary StackGuardian platform resources and AWS infrastructure to enable private runner execution. It creates a runner group on the StackGuardian platform, an S3 bucket for artifact storage, and the IAM roles required for secure cross-account access.

### What Gets Created

- **StackGuardian Runner Group**: Platform resource for organizing and managing private runners
- **StackGuardian Connector**: AWS RBAC connector for secure S3 access from the StackGuardian platform
- **S3 Bucket**: Storage backend for runner artifacts (optional - can use existing bucket)
- **IAM Role**: Cross-account role for StackGuardian platform access to S3
- **IAM Policy**: Scoped permissions for S3 bucket operations

## Prerequisites

- StackGuardian API key (starts with `sgu_` for user keys or `sgo_` for organization keys)
- AWS credentials with permissions to create S3 buckets and IAM roles
- Terraform >= 1.0

## Quick Start

### Step 1: Configure Variables

Create a `terraform.tfvars` file:

```hcl
stackguardian = {
  api_key  = "sgu_your_api_key_here"
  api_uri  = "https://api.app.stackguardian.io"  # EU1 or use US1 endpoint
  org_name = "your-org-name"  # Optional if SG_ORG_ID env var is set
}

aws_region = "eu-central-1"
```

### Step 2: Deploy

```bash
terraform init
terraform plan
terraform apply
```

### Basic Configuration Example

```hcl
module "runner_group" {
  source = "./stackguardian_runner_group"

  stackguardian = {
    api_key = "sgu_your_api_key"
  }

  aws_region = "eu-central-1"
}
```

## Configuration

### Required Parameters

| Parameter | Description | Type |
|-----------|-------------|------|
| `stackguardian.api_key` | StackGuardian API key (must start with `sgu_` or `sgo_`) | `string` |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `stackguardian.api_uri` | StackGuardian API endpoint | `https://api.app.stackguardian.io` |
| `stackguardian.org_name` | Organization name (extracted from env if not provided) | `""` |
| `aws_region` | Target AWS region | `eu-central-1` |
| `create_storage_backend` | Whether to create a new S3 bucket | `true` |
| `existing_s3_bucket_name` | Existing S3 bucket name (when `create_storage_backend = false`) | `""` |
| `force_destroy_storage_backend` | Force destroy S3 bucket on module destruction | `false` |
| `override_names.global_prefix` | Prefix for resource naming | `SG_RUNNER` |
| `override_names.include_org_in_prefix` | Append org name to prefix | `false` |
| `override_names.runner_group_name` | Override runner group name | Auto-generated |
| `override_names.connector_name` | Override connector name | Auto-generated |
| `max_runners` | Maximum number of runners in the group | `3` |

### Configuration Examples

#### Basic Configuration

```hcl
module "runner_group" {
  source = "./stackguardian_runner_group"

  stackguardian = {
    api_key = var.sg_api_key
  }

  aws_region = "eu-central-1"
}
```

#### Advanced Configuration

```hcl
module "runner_group" {
  source = "./stackguardian_runner_group"

  stackguardian = {
    api_key  = var.sg_api_key
    api_uri  = "https://api.us.stackguardian.io"
    org_name = "my-organization"
  }

  aws_region              = "us-east-1"
  create_storage_backend  = true
  force_destroy_storage_backend = false
  max_runners             = 10

  override_names = {
    global_prefix         = "PROD_RUNNER"
    include_org_in_prefix = true
    runner_group_name     = "production-runners"
    connector_name        = "prod-s3-connector"
  }
}
```

#### Using Existing S3 Bucket

```hcl
module "runner_group" {
  source = "./stackguardian_runner_group"

  stackguardian = {
    api_key = var.sg_api_key
  }

  aws_region             = "eu-central-1"
  create_storage_backend = false
  existing_s3_bucket_name = "my-existing-bucket"
}
```

## Usage

### Deployment Commands

```bash
# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Apply configuration
terraform apply

# View outputs
terraform output runner_group_name
terraform output -raw runner_group_token  # Sensitive
```

### Cleanup

```bash
# Destroy all resources
terraform destroy
```

**Warning**: If `force_destroy_storage_backend = false` (default), the S3 bucket will not be deleted if it contains objects. Empty the bucket first or set `force_destroy_storage_backend = true`.

## Architecture

### Resource Organization

| File | Purpose |
|------|---------|
| `provider.tf` | Provider configuration (AWS, StackGuardian, external, random) |
| `variables.tf` | Input variable definitions |
| `locals.tf` | Computed values and naming logic |
| `runner_group.tf` | StackGuardian runner group resource |
| `connector.tf` | StackGuardian AWS RBAC connector |
| `storage_backend.tf` | S3 bucket and CORS configuration |
| `storage_backend_role.tf` | IAM role and policy for S3 access |
| `data.tf` | Data sources (runner group token) |
| `outputs.tf` | Module outputs |

### Resource Naming Convention

Resources are named using the pattern: `{prefix}-{resource-type}-{account_id}`

- Default prefix: `SG_RUNNER`
- With org in prefix: `SG_RUNNER_{org_name}`
- Examples:
  - Runner group: `SG_RUNNER-runner-group-123456789012`
  - Connector: `SG_RUNNER-private-runner-backend-123456789012`
  - IAM role: `SG_RUNNER-private-runner-s3-role`

### Security Model

The module implements secure cross-account access:

1. **IAM Role Trust Policy**: Allows StackGuardian AWS accounts (163602625436, 476299211833) and your account to assume the role
2. **External ID**: Random 24-character string prefixed with org name prevents confused deputy attacks
3. **Scoped S3 Permissions**: Only necessary S3 actions are permitted on the specific bucket
4. **Public Access Block**: S3 bucket blocks all public access by default

## Troubleshooting

### Common Issues

1. **API Key Validation Error**
   - Ensure API key starts with `sgu_` (user key) or `sgo_` (organization key)
   - Verify the key has permissions for your organization

2. **Organization Name Not Found**
   - Provide `stackguardian.org_name` explicitly, or
   - Set `SG_ORG_ID` environment variable

3. **S3 Bucket Already Exists**
   - Bucket names are globally unique; the module uses random prefixes
   - If using existing bucket, ensure `create_storage_backend = false`

4. **Permission Denied on Destroy**
   - Empty the S3 bucket first, or
   - Set `force_destroy_storage_backend = true`

### Debugging Commands

```bash
# Check Terraform state
terraform state list

# View specific resource
terraform state show module.runner_group.stackguardian_runner_group.this

# Enable debug logging
export TF_LOG=DEBUG
terraform apply
```

## Outputs

| Output | Description |
|--------|-------------|
| `runner_group_name` | The name of the StackGuardian runner group |
| `runner_group_id` | The ID of the StackGuardian runner group |
| `runner_group_token` | Token for runner registration (sensitive) |
| `runner_group_url` | Direct URL to the runner group in the web console (sensitive) |
| `connector_name` | The name of the StackGuardian connector |
| `connector_id` | The ID of the StackGuardian connector |
| `connector_external_id` | External ID for cross-account S3 access (sensitive) |
| `s3_bucket_name` | The name of the S3 bucket |
| `s3_bucket_arn` | The ARN of the S3 bucket |
| `storage_backend_role_arn` | ARN of the IAM role for storage backend access |
| `storage_backend_role_name` | Name of the IAM role |
| `sg_org_name` | The StackGuardian organization name (sensitive) |
| `sg_api_uri` | The StackGuardian API URI |
| `aws_region` | The AWS region |

## Security Considerations

- **API Key Storage**: Store your StackGuardian API key securely (environment variables, secrets manager)
- **S3 Encryption**: Consider enabling server-side encryption on the S3 bucket
- **IAM Least Privilege**: The module creates scoped IAM policies with only required permissions
- **Network Security**: S3 bucket CORS is configured to allow only the StackGuardian platform origin
- **Public Access**: S3 bucket public access is blocked by default

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 4.0 |
| stackguardian | >= 1.3.3 |
| external | >= 2.0 |
| random | >= 3.0 |

## Next Steps

After deploying this module:

1. Use the `runner_group_name` and `runner_group_token` outputs to deploy runners using the `aws_autoscaled_runner` or `aws_runner` modules
2. Pass `storage_backend_role_arn` and `s3_bucket_name` to runner deployment modules
3. Access your runner group in the StackGuardian web console using the `runner_group_url` output

## Support

- [StackGuardian Documentation](https://docs.stackguardian.io/)
- [StackGuardian Terraform Provider](https://registry.terraform.io/providers/StackGuardian/stackguardian/latest/docs)
- [GitHub Issues](https://github.com/StackGuardian/terraform-stackguardian-modules/issues)
