# Azure OIDC Identity

Creates an Entra application, service principal, subscription assignment, and federated credential. The managing identity needs Microsoft Graph application-management plus subscription role-assignment privileges. `role_definition_name` defaults to high-privilege `Contributor`.

```hcl
module "azure_oidc" {
  source                   = "./azure_oidc"
  subscription_id          = "00000000-0000-0000-0000-000000000000"
  tenant_id                = "00000000-0000-0000-0000-000000000000"
  client_id                = "00000000-0000-0000-0000-000000000000"
  client_secret            = var.azure_management_secret
  application_display_name = "stackguardian-oidc"
  stackguardian_org_name   = "example-org"
}
```

Outputs: `client_id`, `tenant_id`, `subscription_id`, `federated_credential_id`.
