# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Breaking
- Replace the singleton root role and assignment inputs with keyed `roles` and `subjects` collections. Roles can independently scope workflow groups, cloud connectors, VCS connectors, and templates; each subject assignment now carries its complete roles list.

### Added
- Add root-level AWS, Azure, and GCP identity wiring so Terraform creates the selected cloud identity and registers its generated identifiers with StackGuardian.
- Add CLI-authenticated AWS and Azure onboarding and guarded destroy tasks with temporary targeted plans and StackGuardian token prompting.

### Changed
- Move AWS region, Azure subscription and tenant IDs, and GCP project IDs into their respective `cloud_connectors` entries instead of using root cloud-provider variables.
- Rebuild the scoped role-v4 permission document from the observed v4 positional path shape, including exact and nested workflow-group paths and matching wildcard arrays.
- Deprecate static AWS and Azure authentication. Static identity modules and static cloud connector kinds now require explicit `allow_static_credentials = true` acknowledgement and emit an apply-time warning.
- Replace the unsafe Taskfile example-copy initialization workflow with non-mutating formatting, source-contract, and isolated validation tasks compatible with Terraform 1.5.7.

### Added
- Add pinned OpenTofu 1.12.5 native tests for role-v4 permission construction and static cloud connector acknowledgement behavior, using isolated mocked plan runs.

## [2.0.0] - 2026-08-12

### Breaking
- Pin Terraform Core to `1.5.7` and upgrade bounded provider ranges: StackGuardian 1.12, AWS 6, AzureRM 5, AzureAD 3.9, and Google 7.
- Replace legacy camelCase/hyphenated inputs, untyped connector objects, root static credential duplicates, and leaf StackGuardian API credential inputs with v2 flat snake_case contracts.
- Migrate roles to `stackguardian_rolev4` and assignments to `roles = [role_name]`. Existing role state requires the documented state remove/import procedure.
- Replace global AWS policy attachments and authoritative GCP service-account IAM policy management with narrowly scoped attachments/members. Existing state needs the documented import procedure before apply.

### Changed
- Correct Azure connector settings to the provider's `arm_tenant_id`, `arm_subscription_id`, `arm_client_id`, and `arm_client_secret` schema.
- Use production StackGuardian OIDC issuer/audience defaults for AWS, Azure, and GCP; expose their configuration inputs.
- Retain configurable permissive defaults: AWS `ReadOnlyAccess`, Azure subscription `Contributor`, and GCP `roles/owner`. These defaults are documented as high-risk where applicable.
- Add validation, sensitive flags, finite Azure secret lifetime, typed VCS credentials, typed cloud connectors, and GCP same-type state moves.

### Added
- Comprehensive README.md with detailed documentation
- Input validation for variables
- Security-focused .gitignore file
- terraform.tfvars.example with all configuration options
- GitHub Actions CI/CD pipeline
- MIT License
- This CHANGELOG.md file

### Fixed
- Syntax errors in team_onboarding_permissions.tf (missing commas)
- Variable type definitions (changed generic `list` to `list(string)`)
- Sensitive variable handling for API keys

### Changed
- Improved variable descriptions and formatting
- Enhanced security practices documentation

### Security
- Added sensitive flag to API key variable
- Improved .gitignore to prevent credential leaks
- Added validation rules for input parameters

## [1.0.0] - 2024-01-XX

### Added
- Initial release of StackGuardian Terraform modules
- Support for workflow groups management
- Cloud connector modules for AWS, Azure, and GCP
- VCS connector modules for GitHub, GitLab, and Bitbucket
- Role and role assignment management
- OIDC setup modules for cloud providers

### Features
- **Workflow Groups**: Create and manage deployment environments
- **Cloud Connectors**: Support for multiple authentication methods
  - AWS: Static keys, RBAC, OIDC
  - Azure: Static credentials, OIDC
  - GCP: Static credentials
- **VCS Integration**: Connect to popular version control systems
- **RBAC**: Comprehensive role-based access control
- **Team Onboarding**: Automated user and group management

### Modules Included
- `stackguardian_workflow_group`
- `stackguardian_connector_cloud`
- `stackguardian_connector_vcs`
- `stackguardian_role`
- `stackguardian_role_assignment`
- `aws_oidc`
- `aws_rbac`
- `azure_oidc`
- `gcp_oidc`
