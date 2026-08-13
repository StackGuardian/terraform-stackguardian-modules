# Azure Static Identity

Creates an Entra application, service principal, finite-lifetime client secret, and subscription assignment. The managing identity needs Microsoft Graph application-management plus subscription role-assignment privileges. `role_definition_name` defaults to high-privilege `Contributor`.

```hcl
module "azure_static" {
  source                   = "./azure_static"
  subscription_id          = "00000000-0000-0000-0000-000000000000"
  tenant_id                = "00000000-0000-0000-0000-000000000000"
  client_id                = "00000000-0000-0000-0000-000000000000"
  client_secret            = var.azure_management_secret
  application_display_name = "stackguardian-static"
}
```

Outputs: `client_id`, `tenant_id`, `subscription_id`, `client_secret_value` (sensitive), `client_secret_id`.
