# AWS Static Connector Identity

> **Deprecated:** Static AWS credentials are retained in Terraform state and can appear in plan artifacts. Prefer `aws_rbac` or `aws_oidc`.

Creates an IAM user and access key for an AWS static connector. The caller needs IAM user and access-key permissions; the generated secret is sensitive but remains in Terraform state. Creation requires an explicit acknowledgement.

```hcl
module "aws_static" {
  source                   = "./aws_static"
  iam_user                 = "stackguardian-static"
  aws_region = "eu-central-1"
  allow_static_credentials = true
}
```

Outputs: `access_key_id`, `secret_access_key` (sensitive).
