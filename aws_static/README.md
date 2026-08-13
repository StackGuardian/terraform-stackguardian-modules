# AWS Static Connector Identity

Creates an IAM user and access key for an AWS static connector. The caller needs IAM user and access-key permissions; the generated secret is sensitive but remains in Terraform state.

```hcl
module "aws_static" {
  source   = "./aws_static"
  iam_user = "stackguardian-static"
  aws_region = "eu-central-1"
}
```

Outputs: `access_key_id`, `secret_access_key` (sensitive).
