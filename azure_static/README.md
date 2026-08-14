# Azure Static Identity

> **Deprecated:** Static Azure credentials are retained in Terraform state and can appear in plan artifacts. Prefer `azure_oidc`.

Creates an Entra application, service principal, finite-lifetime client secret, and subscription assignment. The managing identity needs Microsoft Graph application-management plus subscription role-assignment privileges and can authenticate with `az login`. `role_definition_name` defaults to high-privilege `Contributor`. Creation requires an explicit acknowledgement.

```hcl
module "azure_static" {
  source                   = "./azure_static"
  subscription_id          = "00000000-0000-0000-0000-000000000000"
  tenant_id                = "00000000-0000-0000-0000-000000000000"
  application_display_name = "stackguardian-static"
  allow_static_credentials = true
}
```

Outputs: `client_id`, `tenant_id`, `subscription_id`, `client_secret_value` (sensitive), `client_secret_id`.
