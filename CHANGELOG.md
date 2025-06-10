# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
