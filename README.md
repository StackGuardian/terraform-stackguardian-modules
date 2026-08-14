# StackGuardian Terraform Modules v2

Terraform modules for StackGuardian onboarding and cloud identity configuration. The root module creates workflow groups, cloud/VCS connectors, keyed roles, and one multi-role assignment per subject. `stackguardian_private_runner/` is explicitly outside the v2 upgrade scope.

## Prerequisites

- Terraform **1.5.7** exactly.
- StackGuardian provider `>= 1.12.0, < 2.0.0`.
- AWS provider `>= 6.58.0, < 7.0.0`, AzureRM `>= 5.0.1, < 6.0.0`, AzureAD `>= 3.9.0, < 4.0.0`, and Google `>= 7.44.0, < 8.0.0` in their applicable modules.
- Credentials authorized to create the selected cloud identities. Azure management needs Microsoft Graph application-management and subscription role-assignment privileges.

Use `terraform.tfvars.example` as a configuration reference. Put secret values in `TF_VAR_*` variables or a secret manager, not version control.

## Static Credential Deprecation

`aws_static`, `azure_static`, and `AWS_STATIC` or `AZURE_STATIC` cloud connectors are deprecated. Static secrets are retained in Terraform state and may appear in plan artifacts, so protect both as sensitive data. Prefer `aws_rbac`, `aws_oidc`, `azure_oidc`, or the corresponding non-static connector kind.

Static authentication requires an explicit acknowledgement. The root acknowledgement is per connector and cannot enable another connector:

```hcl
cloud_connectors = {
  legacy-aws = {
    kind                     = "AWS_STATIC"
    allow_static_credentials = true
    aws_region               = "eu-central-1"
  }
}
```

Standalone `aws_static` and `azure_static` modules also require `allow_static_credentials = true`. Terraform emits a deprecation warning during apply after acknowledgement.

## Cloud Onboarding

The root creates the selected cloud identity and registers the generated identifiers with StackGuardian. It does not require you to manually supply an AWS role ARN, an Azure application client ID, or a GCP external-account configuration for OIDC connectors.

- AWS uses the standard AWS provider credential chain. Authenticate first with your normal profile or `aws sso login`, then customize `examples/aws-oidc.tfvars.example` and run `task onboard:aws`. The task creates the `api.app.stackguardian.io` IAM OIDC provider when it is absent, or imports an existing unmanaged provider instead of attempting to recreate it.
- Azure uses the active Azure CLI identity. Authenticate with `az login`, set the connector's `azure_subscription_id` and `azure_tenant_id` to match the active account, customize `examples/azure-oidc.tfvars.example`, and run `task onboard:azure`.
- GCP uses gcloud application-default credentials. Run `gcloud auth application-default login`, configure a `GCP_OIDC` connector with its `gcp_project_id` and workload identity names, and apply a reviewed plan.

Both onboarding tasks use `TF_VAR_stackguardian_api_key` when it is set. Otherwise they prompt for the StackGuardian API token without saving it to a file. Tasks write full plans to the working directory, apply that exact plan, and retain it for inspection: `onboard-aws.tfplan`, `onboard-azure.tfplan`, `destroy-aws.tfplan`, or `destroy-azure.tfplan`. These ignored files can be overridden with `ONBOARD_PLAN_FILE`. A full plan applies every resource declared by the selected vars file, including workflow groups, roles, and assignments. Override `ONBOARD_VARS_FILE` or `ONBOARD_CONNECTOR_NAME` when using a differently named connector fixture.

Use `task destroy:aws` or `task destroy:azure` to remove a connector trial. Each asks you to type the connector name before it destroys resources. AWS teardown retains any account-level `api.app.stackguardian.io` OIDC provider because it may be shared by multiple StackGuardian roles.

## V2 Inputs

| v1 input | v2 input |
| --- | --- |
| `api_key` | `stackguardian_api_key` |
| `org_name` | `stackguardian_org_name` |
| `user_or_group` | `subject` |
| `connector_type` | `kind` in `cloud_connectors` |
| `cloud_connector_name` | `name` in `cloud_connectors` |
| `aws_default_region` | `aws_region` in the AWS connector |
| `armTenantId`, `armSubscriptionId`, `armClientId`, `armClientSecret` | `azure_tenant_id`, `azure_subscription_id`, `azure_client_id`, `azure_client_secret` in the Azure connector |
| `role_arn`, `role_external_id` | `aws_role_arn`, `aws_external_id` |
| `aws_oidc.region`, `role_name`, `account_number`, `aws_policy` | `aws_region`, `iam_role_name`, `aws_account_id`, `policy_arn` |
| `aws_rbac.aws_role_name`, `aws_policy` | `iam_role_name`, `policy_arn` |
| `azure_static.AD_name` | `application_display_name` |
| `azure_oidc.sg_org_name` | `stackguardian_org_name` |
| `gcp_oidc.project`, `sg-org-id` | `gcp_project_id` in the GCP connector, `stackguardian_org_name` |

Legacy aliases are intentionally unavailable. The root configures StackGuardian once; standalone StackGuardian leaf modules inherit provider configuration from their caller and do not accept API credentials.

## Onboarding Configuration

`terraform.tfvars.example` is a complete multi-role example. It includes a local user, a qualified SSO user, and an SSO group. `workflow_groups` is a list. Cloud connectors are keyed by connector name. The unchanged VCS connector leaf module retains its required `name` field; in root configuration it must equal its map key.

Each `roles` map key is the StackGuardian role name. A role may scope workflow groups, cloud connectors, VCS connectors, and templates, but must include at least one non-empty scope. Role connector and workflow references are the relevant root map keys. Empty scope categories produce no permissions.

Each `subjects` map key is a local email, qualified SSO email, or qualified SSO group such as `okta/platform-engineers`. A subject has one assignment resource containing its complete, non-empty, duplicate-free `roles` list. `entity_type` defaults to `EMAIL`; use `GROUP` for group subjects.

VCS credentials remain sensitive and are stored in Terraform state. Keep real values in an ignored secret vars file, a generated `terraform.tfvars.json`, or JSON-encoded `TF_VAR_vcs_connectors`; examples use literal placeholders.

## Permissions And Defaults

- `aws_static` is deprecated, needs IAM user/key permissions, and stores a generated static key in state. Use `aws_rbac` or `aws_oidc` when possible.
- `aws_rbac` and `aws_oidc` need IAM role/policy/OIDC permissions. `policy_arn` defaults to `ReadOnlyAccess`; override it for least privilege. RBAC keeps the two historical trusted StackGuardian accounts by default.
- `azure_static` is deprecated. It and `azure_oidc` create an Entra application and assign `Contributor` at subscription scope by default. This is high privilege; use `role_definition_name` to reduce it. Static passwords expire after `8760h` by default; prefer `azure_oidc`.
- `gcp_oidc` needs service-account, workload-identity, and project IAM permissions. `project_role` defaults to high-privilege `roles/owner`; override it for production. Validate the configured issuer, audience, and exact `/orgs/<stackguardian_org_name>` subject against a real StackGuardian token before applying.
- Cloud and VCS connector modules require access to create StackGuardian connectors. They reject missing, mismatched, or conflicting credentials.
- Role, assignment, and workflow-group modules require StackGuardian role-management permission.

## Role v4 State Migration

The role resource changes from `stackguardian_role` to `stackguardian_rolev4`; this cannot use a `moved` block or `terraform state mv`. During a maintenance window with exclusive backend locking, back up state and record the existing permissions, then run:

```bash
terraform state rm 'module.stackguardian_role.stackguardian_role.role'
terraform import 'module.stackguardian_role.stackguardian_rolev4.role' '<role-name>'
terraform plan
```

For standalone role usage, omit `module.stackguardian_role.`. Review the v4 `allowed_permissions`, apply the reviewed update, then run a second plan and test an allowed and denied path. Do not use `state mv`; roll back only by restoring the backed-up state/configuration.

Before replacing the former authoritative GCP IAM policy, add and import `google_service_account_iam_member.self_workload_identity`, then remove only the old policy state binding. Likewise, import the existing AWS role-policy attachment when converting from the legacy global attachment. Export existing IAM bindings first and verify the plan cannot remove unrelated principals.

## Multi-Role Migration

This root interface is a breaking change. Back up state, acquire an exclusive backend lock, convert the old values into one `roles` entry and one `subjects` entry, and review the resulting plan. Preserve workflow names and connector names as the new list values and map keys to retain their existing `for_each` addresses. A key or name change intentionally renames a resource and needs separate migration handling.

Move the former singleton role and assignment addresses for each installation after converting configuration:

```bash
terraform state mv \
  'module.stackguardian_role.stackguardian_rolev4.role' \
  'module.stackguardian_role["engineering-developer"].stackguardian_rolev4.role'
terraform state mv \
  'module.stackguardian_role_assignment.stackguardian_role_assignment.sg_user' \
  'module.stackguardian_role_assignment["developer@example.invalid"].stackguardian_role_assignment.sg_user'
```

Run a reviewed plan after the moves before applying. The v4 resource-type migration instructions above still apply when migrating from a pre-v4 state address.

## Module Usage

Each module has a short usage and outputs reference in its directory README. Run `terraform init -upgrade`, `terraform validate`, and a reviewed plan from the specific module directory. Lock files are deliberately not committed because callers initialize independently.

## Local Checks

Run `task check` for formatting. Run `task validate` for isolated `terraform init -backend=false` and `terraform validate` checks; it copies configurations to a temporary directory and requires network access for provider downloads. Terraform is pinned to `1.5.7` in `.terraform-version`; tasks use `tfenv` when available, otherwise they check the installed `terraform` binary and print installation guidance when it does not match.

Run `task test` for native OpenTofu tests. The checked-in `.opentofu-version` pins OpenTofu 1.12.5; tasks use `tofuenv` when available, otherwise they check the installed `tofu` binary and print installation guidance when it does not match. The task copies tested modules to a temporary directory, relaxes only the copied Terraform 1.5.7 version constraint, and resolves the StackGuardian provider from the Terraform Registry because it is not mirrored by the OpenTofu Registry. Tests use mocked StackGuardian providers and plan-only runs, so they do not apply cloud infrastructure or call the StackGuardian API. Cloud applies and remote API behavior remain integration tests.

## Dev Container And CI

The `.devcontainer` image installs the versions pinned in `.terraform-version`, `.opentofu-version`, and `.task-version`, and is supported on Linux `amd64` and `arm64`. Open the repository in a Dev Container to use the same checks environment as CI. GitHub Actions runs `task check`, `task validate`, and `task test` through this devcontainer for pull requests and pushes to `main`.
