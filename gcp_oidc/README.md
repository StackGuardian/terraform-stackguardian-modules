# GCP OIDC Identity

Creates a service account, workload identity pool/provider, and narrowly scoped IAM members. The caller needs service-account, workload-identity, and project-IAM permissions. `project_role` defaults to high-privilege `roles/owner`; override it for production.

```hcl
module "gcp_oidc" {
  source                                  = "./gcp_oidc"
  project_id                              = "example-project"
  region                                  = "europe-west3"
  stackguardian_org_id                    = "example-org-id"
  service_account_id                      = "stackguardian"
  workload_identity_pool_id               = "stackguardian"
  workload_identity_pool_provider_id      = "stackguardian-oidc"
  workload_identity_pool_display_name     = "StackGuardian"
  project_role                            = "roles/viewer"
}
```

Validate issuer, audience, and the exact serialized subject with a real token before applying. Import the self-member binding before removing the previous authoritative IAM-policy state.

Outputs: `service_account_email`, `workload_identity_pool_id`, `workload_identity_pool_provider_id`.
