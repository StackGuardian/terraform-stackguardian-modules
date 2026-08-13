# StackGuardian Cloud Connector

Creates one `AWS_STATIC`, `AWS_RBAC`, `AWS_OIDC`, `AZURE_STATIC`, `AZURE_OIDC`, or `GCP_OIDC` connector. Configure the StackGuardian provider in the calling root. Credential fields are typed, sensitive where secret, and persisted in Terraform state.

```hcl
module "connector" {
  source           = "./stackguardian_connector_cloud"
  connector_name   = "aws-rbac"
  connector_kind   = "AWS_RBAC"
  aws_role_arn     = "arn:aws:iam::123456789012:role/StackGuardianRole"
  aws_external_id  = var.external_id
}
```

Outputs: `connector_name`, `connector_kind`, `connector_id`.
