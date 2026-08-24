# StackGuardian Runner Group - AWS

> Part of [StackGuardian Private Runner](../../README.md) — [AWS stack overview](../DOCUMENTATION.md) · [platform template doc](DOCUMENTATION.md)

Provisions a StackGuardian Runner Group with an S3 storage backend and the `AWS_RBAC`
connector the platform uses to reach it.

This module requires **only** the AWS provider. The platform-side resources (runner
group, connector, registration token) live in the shared, cloud-agnostic
[`runner_group/`](../../runner_group/) module, which this module calls — so an AWS
deployment never initializes `azurerm` or `azuread`. The Azure equivalent is
[`azure/runner_group/`](../../azure/runner_group/).

## What Gets Created

- **S3 bucket** with public access blocked and CORS limited to the StackGuardian
  platform origin (when `create_storage_backend = true`).
- **IAM role + policy** scoped to the bucket. The trust policy allows the StackGuardian
  AWS accounts (`163602625436`, `476299211833`) and the caller's own account, gated by
  an external ID of the form `{org_name}:{24-char-random}`.
- **StackGuardian Runner Group** with `max_number_of_runners` and default tags.
- **StackGuardian Connector** (`AWS_RBAC`) wired to the role and external ID above.

## Prerequisites

- StackGuardian API key (`sgu_*` user key, `sgo_*` org key, or a `${secret::SECRET_NAME}`
  reference).
- OpenTofu >= 1.7 or Terraform >= 1.3.
- AWS credentials with permission to create S3 buckets and IAM roles.

## Quick Start

`terraform.tfvars`:

```hcl
stackguardian = {
  api_key  = "sgu_your_api_key_here"
  api_uri  = "https://api.app.stackguardian.io"
  org_name = "your-org-name"
}

aws_region = "eu-central-1"
```

```bash
tofu init
tofu plan
tofu apply
```

### As a module

```hcl
module "runner_group" {
  source = "./stackguardian_private_runner/aws/runner_group"

  stackguardian = {
    api_key = "sgu_your_api_key"
  }

  aws_region  = "eu-central-1"
  max_runners = 3
}
```

## Configuration

### Required Parameters

| Parameter | Description | Type |
|-----------|-------------|------|
| `stackguardian.api_key` | StackGuardian API key (must start with `sgu_` or `sgo_`) | `string` (sensitive) |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `stackguardian.api_uri` | StackGuardian API endpoint (EU1 / US1 / DASH) | `https://api.app.stackguardian.io` |
| `stackguardian.org_name` | Organization name; falls back to the `SG_ORG_ID` env var | `""` |
| `aws_region` | Target AWS region | `eu-central-1` |
| `create_storage_backend` | Create a new S3 bucket | `true` |
| `existing_s3_bucket_name` | Existing bucket name (when `create_storage_backend = false`) | `""` |
| `force_destroy_storage_backend` | Force destroy the bucket on `destroy` — deletes all objects | `false` |
| `override_names.global_prefix` | Prefix for all resource names | `SG_RUNNER` |
| `override_names.include_org_in_prefix` | Append the org name to the prefix (e.g. `SG_RUNNER_demo-org`) | `false` |
| `override_names.runner_group_name` | Override the runner group name | (auto-generated) |
| `override_names.connector_name` | Override the connector name | (auto-generated) |
| `max_runners` | Maximum runners allowed in the group | `3` |

### Naming

With defaults, resources are named from `{effective_prefix}` (the `global_prefix`,
optionally suffixed with the org name) and the AWS account ID:

- Runner group: `{effective_prefix}-runner-group-{account_id}`
- Connector: `{effective_prefix}-private-runner-backend-{account_id}`
- IAM role: `{effective_prefix}-private-runner-s3-role`
- S3 bucket: `{8-char-random}-private-runner-storage-backend`

## Outputs

| Output | Description |
|--------|-------------|
| `runner_group_name` / `runner_group_id` | Name of the created runner group |
| `runner_group_token` | Registration token for runners (sensitive) |
| `runner_group_url` | Direct link to the runner group in the web console |
| `connector_name` / `connector_id` | Name of the AWS connector |
| `connector_external_id` | External ID enforced by the role's trust policy |
| `s3_bucket_name` / `s3_bucket_arn` | Storage backend bucket |
| `storage_backend_role_arn` / `storage_backend_role_name` | IAM role runners assume |
| `sg_org_name` / `sg_api_uri` / `aws_region` | Resolved platform and region settings |

Feed `runner_group_name`, `runner_group_token`, and `storage_backend_role_arn` into
[`aws/single_runner`](../single_runner/) or [`aws/autoscaling_group`](../autoscaling_group/).
See [`examples/aws/quickstart`](../../examples/aws/quickstart/) for the whole stack wired
together.

## Security Notes

- The bucket blocks all public access and accepts browser requests only from the
  StackGuardian console origin.
- The IAM policy grants only the S3 actions runners need, scoped to the one bucket.
- Cross-account access is gated by a random external ID, so a leaked role ARN alone is
  not enough to assume the role.
- `force_destroy_storage_backend` deletes every object in the bucket on `destroy`. Leave
  it off unless you mean it.
