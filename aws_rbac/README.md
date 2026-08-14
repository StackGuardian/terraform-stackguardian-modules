# AWS RBAC Identity

Creates an IAM role trusted by StackGuardian accounts. The caller needs IAM role and policy-attachment permissions. `policy_arn` defaults to `ReadOnlyAccess`; supply a least-privilege policy for production.

```hcl
module "aws_rbac" {
  source           = "./aws_rbac"
  iam_role_name    = "StackGuardianRole"
  role_external_id = "example-org:external-id"
}
```

The default `trusted_account_ids` preserves the two historical StackGuardian accounts and is configurable.

Output: `iam_role_arn`.
