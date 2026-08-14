# AWS OIDC Identity

Creates an AWS IAM OIDC provider, IAM role, and role-policy attachment. The caller needs IAM OIDC, role, and policy-attachment permissions. `policy_arn` defaults to `ReadOnlyAccess` and should be narrowed for production.

```hcl
module "aws_oidc" {
  source                 = "./aws_oidc"
  aws_region             = "eu-central-1"
  iam_role_name          = "StackGuardianOidcRole"
  stackguardian_org_name = "example-org"
}
```

Outputs: `oidc_provider_arn`, `oidc_role_arn`.
