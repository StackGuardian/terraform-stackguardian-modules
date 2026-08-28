# StackGuardian Runner Group - AWS Template

Deploy a StackGuardian Runner Group with an S3 storage backend directly from the
StackGuardian platform.

## Overview

This template provisions everything required to run private runners on AWS: a runner
group on the StackGuardian platform, a private S3 bucket for workflow artifacts, and a
cross-account IAM role that lets StackGuardian and your runners reach it. Tags are
applied automatically to the StackGuardian resources — see **Tags** below.

Deploying on Azure instead? Use the **StackGuardian Runner Group - Azure** template.

### What This Template Creates

- **Runner Group** — A dedicated group on the StackGuardian platform to organize your
  private runners.
- **S3 Storage Bucket** — Private bucket for workflow outputs and artifacts (or point at
  an existing bucket).
- **IAM Access Role** — Cross-account role with an external ID for secure platform access.
- **AWS Connector** — `AWS_RBAC` integration between StackGuardian and your AWS account.

## Prerequisites

- A StackGuardian API key for your organization.
- AWS account credentials in your StackGuardian workspace with permissions to create S3
  buckets and IAM roles.

## Template Parameters

### Required Parameters

| Parameter | Description | Type |
|-----------|-------------|------|
| API Key | Your organization's API key on the StackGuardian Platform (`sgu_*`/`sgo_*`) or a secret reference (`${secret::SECRET_NAME}`) | Password |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| API Region | Your StackGuardian platform region (EU1 / US1 / DASH) | EU1 - Europe |
| Organization Name | Your organization name (auto-detected from environment if omitted) | Auto-detected |
| AWS Region | The target AWS Region for the S3 bucket and IAM resources | eu-central-1 |
| Create Storage Backend | Whether to create a new S3 bucket | Enabled |
| Existing S3 Bucket Name | Name of an existing S3 bucket to use (when not creating new) | — |
| Force Destroy Storage Backend | Delete all data in the S3 bucket on destroy (use with caution) | Disabled |
| Global Prefix | Prefix for the runner group and connector names. Leave empty to omit it | SG_RUNNER |
| Runner Group Name | Name half of the runner group; the full name is `{prefix}-{name}` | 6-character random string |
| Connector Name | Name half of the connector | Same as the runner group |
| Maximum Runners | Maximum number of runners allowed in the group | 3 |

## Important Notes

**API Key Security**: The API key is stored securely and used only to authenticate with
the StackGuardian platform. It must be `sgu_*` (user key), `sgo_*` (organization key), or
a `${secret::SECRET_NAME}` reference.

**Storage Backend Options**: You can either create a new bucket (recommended) or point to
an existing one. When using an existing bucket, ensure it has the appropriate permissions
and CORS configuration.

**Resource Naming**: The runner group and the connector are named `{prefix}-{name}`, or
just `{name}` when **Global Prefix** is empty. Leave **Runner Group Name** empty and the
name half is a 6-character random string, which is all the uniqueness a runner group
needs. Set it when you want a stable, project-specific name. The connector shares the
runner group's name — they live in separate API namespaces, so there is nothing to clash
with. The AWS resources keep their own scheme: the IAM role is
`{prefix}-private-runner-s3-role` and the S3 bucket is
`{8-char-random}-private-runner-storage-backend`.

**Tags**: The platform models tags as a flat list of strings — there are no keys — capped
at 10. The runner group and the connector both get `StackGuardian Private Runner`,
`Managed by IaC`, `aws`, the AWS account ID, the **Global Prefix**, and the region. The
account ID is a tag rather than part of the name. The organization name and the runner
group's own name are deliberately not tagged: a runner group only ever lives in one org,
and its name is not information a tag adds.

**Data Retention**: **Force Destroy Storage Backend** deletes all bucket contents on
destroy. Leave it disabled to protect your data.

## Outputs

| Output | Description |
|--------|-------------|
| Runner Group Name | Name of the created runner group, used in workflow configurations |
| Runner Group Token | Authentication token for registering runners (sensitive) |
| Runner Group URL | Direct link to manage the runner group in the StackGuardian console |
| Connector Name | Name of the AWS connector integration |
| Connector External ID | External ID enforced by the IAM role's trust policy |
| S3 Bucket Name | Name of the storage bucket |
| S3 Bucket ARN | ARN of the storage bucket |
| Storage Backend Role ARN | IAM role ARN required by AWS runner instances |
| Storage Backend Role Name | IAM role name for the storage backend |
| Runner Group ID | Identifier of the runner group (same value as the name) |
| Connector ID | Identifier of the AWS connector (same value as the name) |
| SG Org Name | Resolved StackGuardian organization name |
| SG API URI | Resolved StackGuardian API endpoint |

## Security Features

- **Private storage** — The S3 bucket has public access fully blocked.
- **Scoped access** — The IAM policy grants only the S3 actions runners need, on the one
  bucket.
- **Cross-account role with external ID** — A leaked role ARN alone cannot be assumed.
- **CORS protection** — The bucket accepts browser requests only from the StackGuardian
  platform origin.
- **Sensitive output protection** — The runner registration token is marked sensitive.

## Usage

After deploying this template, use the outputs to:

1. **Deploy Runners** — Pass `runner_group_name`, `runner_group_token`, `s3_bucket_name`,
   and `storage_backend_role_arn` to the AWS Autoscaled Runner / AWS Runner template.
2. **Configure Workflows** — Reference the runner group in your workflow configurations to
   execute jobs on private runners.
3. **Monitor Runners** — Open the runner group URL to view runner status and manage the
   group.
