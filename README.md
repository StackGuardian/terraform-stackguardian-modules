# StackGuardian Terraform Modules

Terraform modules for StackGuardian onboarding and cloud identity configuration. The root module creates workflow groups, cloud/VCS connectors, keyed roles, and one multi-role assignment per subject.

## Prerequisites

- Terraform **1.5.7** exactly.
- StackGuardian provider `>= 1.12.0, < 2.0.0`.
- AWS provider `>= 6.58.0, < 7.0.0`, AzureRM `>= 5.0.1, < 6.0.0`, AzureAD `>= 3.9.0, < 4.0.0`, and Google `>= 7.44.0, < 8.0.0` in their applicable modules.
- Credentials authorized to create the selected cloud identities. Azure management needs Microsoft Graph application-management and subscription role-assignment privileges.

Use `terraform.tfvars.example` as a configuration reference. Put secret values in `TF_VAR_*` variables or a secret manager, not version control.

## How To Use

1. Copy `terraform.tfvars.example` to an ignored `terraform.tfvars` file and replace its placeholders.
2. Set `TF_VAR_stackguardian_api_key` through a secret manager or environment variable.
3. Authenticate to each cloud used by `cloud_connectors`.
4. Run `terraform init`, review `terraform plan`, then run `terraform apply`.

For AWS and Azure OIDC onboarding, customize the matching file in `examples/` and use `task onboard:aws` or `task onboard:azure`. Those tasks authenticate through the local cloud CLI, create the selected cloud identity, and apply a reviewed plan.

## Static Credentials

`AWS_STATIC` and `AZURE_STATIC` are supported only when `allow_static_credentials = true` is set on that connector. Static secrets are retained in Terraform state and may appear in plan artifacts. Prefer `AWS_RBAC`, `AWS_OIDC`, `AZURE_OIDC`, or `GCP_OIDC` whenever possible.

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

## Onboarding Configuration

`terraform.tfvars.example` is a complete multi-role configuration. The root accepts these top-level collections:

- `workflow_groups`: unique names of workflow groups to create.
- `cloud_connectors`: a map keyed by connector name. Each value selects one cloud `kind` and supplies the corresponding identity settings. The root creates the selected identity and registers it with StackGuardian.
- `vcs_connectors`: a map keyed by connector name. Each value supplies one GitHub, GitLab, or Bitbucket credential configuration. Its `name` must match the map key.
- `roles`: a map keyed by StackGuardian role name. Each role references one or more workflow groups, cloud connectors, VCS connectors, or templates.
- `subjects`: a map keyed by a local email or qualified SSO subject. Each subject receives one or more role names in one assignment resource.

Role references use the corresponding collection keys. A role must include at least one non-empty scope. Empty scope categories produce no permissions.

Subjects can be local emails such as `developer@example.invalid`, qualified SSO emails such as `okta/developer@example.invalid`, or SSO groups such as `okta/platform-engineers`. `entity_type` defaults to `EMAIL`; set it to `GROUP` for a group. Role lists must be non-empty and duplicate-free.

VCS credentials remain sensitive and are stored in Terraform state. Keep real values in an ignored secret vars file, a generated `terraform.tfvars.json`, or JSON-encoded `TF_VAR_vcs_connectors`; examples use literal placeholders.

## Permissions And Defaults

- `aws_static` is deprecated, needs IAM user/key permissions, and stores a generated static key in state. Use `aws_rbac` or `aws_oidc` when possible.
- `aws_rbac` and `aws_oidc` need IAM role/policy/OIDC permissions. `policy_arn` defaults to `ReadOnlyAccess`; override it for least privilege. RBAC keeps the two historical trusted StackGuardian accounts by default.
- `azure_static` is deprecated. It and `azure_oidc` create an Entra application and assign `Contributor` at subscription scope by default. This is high privilege; use `role_definition_name` to reduce it. Static passwords expire after `8760h` by default; prefer `azure_oidc`.
- `gcp_oidc` needs service-account, workload-identity, and project IAM permissions. `project_role` defaults to high-privilege `roles/owner`; override it for production. Validate the configured issuer, audience, and exact `/orgs/<stackguardian_org_name>` subject against a real StackGuardian token before applying.
- Cloud and VCS connector modules require access to create StackGuardian connectors. They reject missing, mismatched, or conflicting credentials.
- Role, assignment, and workflow-group modules require StackGuardian role-management permission.

## Module Usage

Each module has a short usage and outputs reference in its directory README. Run `terraform init -upgrade`, `terraform validate`, and a reviewed plan from the specific module directory. Lock files are deliberately not committed because callers initialize independently.

## Local Checks

Run `task check` for formatting. Run `task validate` for isolated `terraform init -backend=false` and `terraform validate` checks; it copies configurations to a temporary directory and requires network access for provider downloads. Terraform is pinned to `1.5.7` in `.terraform-version`; tasks use `tfenv` when available, otherwise they check the installed `terraform` binary and print installation guidance when it does not match.

Run `task test` for native OpenTofu tests. The checked-in `.opentofu-version` pins OpenTofu 1.12.5; tasks use `tofuenv` when available, otherwise they check the installed `tofu` binary and print installation guidance when it does not match. The task copies tested modules to a temporary directory, relaxes only the copied Terraform 1.5.7 version constraint, and resolves the StackGuardian provider from the Terraform Registry because it is not mirrored by the OpenTofu Registry. Tests use mocked StackGuardian providers and plan-only runs, so they do not apply cloud infrastructure or call the StackGuardian API. Cloud applies and remote API behavior remain integration tests.

## Dev Container And CI

The `.devcontainer` image installs the versions pinned in `.terraform-version`, `.opentofu-version`, and `.task-version`, and is supported on Linux `amd64` and `arm64`. Open the repository in a Dev Container to use the same checks environment as CI. GitHub Actions runs `task check`, `task validate`, and `task test` through this devcontainer for pull requests and pushes to `main`.
