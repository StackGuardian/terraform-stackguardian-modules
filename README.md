# StackGuardian Terraform Modules

A comprehensive collection of Terraform modules for onboarding and managing StackGuardian platform resources. This repository provides everything you need to set up team access, cloud connectors, workflow groups, and role-based access control (RBAC) for your StackGuardian organization.

## 🚀 Overview

StackGuardian is a cloud infrastructure management platform that helps organizations manage their Infrastructure as Code (IaC) deployments across multiple cloud providers. This Terraform module collection automates the setup of:

- **Workflow Groups** - Organize deployments by environment (Dev, Test, Staging, Prod)
- **Cloud Connectors** - Secure connections to AWS, Azure, and GCP
- **VCS Connectors** - Integration with GitHub, GitLab, and Bitbucket
- **Roles & Permissions** - Custom roles with granular permissions
- **User/Group Management** - Assign roles to users and groups
- **OIDC Setup** - Optional OpenID Connect provider configuration

## 📋 Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- StackGuardian account with API access
- Cloud provider accounts (AWS/Azure/GCP) if using cloud connectors
- VCS provider access tokens (GitHub/GitLab/Bitbucket) if using VCS connectors

## 🏗️ Module Architecture

```
terraform-stackguardian-modules/
├── main.tf                           # Root module orchestration
├── variables.tf                      # Input variables
├── provider.tf                       # Provider configurations
├── terraform.tfvars                  # Example configuration
├── stackguardian_workflow_group/     # Workflow group module
├── stackguardian_connector_cloud/    # Cloud connector module
├── stackguardian_connector_vcs/      # VCS connector module
├── stackguardian_role/               # Role management module
├── stackguardian_role_assignment/    # Role assignment module
├── aws_oidc/                         # AWS OIDC setup module
├── aws_rbac/                         # AWS RBAC setup module
├── azure_oidc/                       # Azure OIDC setup module
└── gcp_oidc/                         # GCP OIDC setup module
```

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd terraform-stackguardian-modules
```

### 2. Configure Variables

Copy the example configuration and customize it for your organization:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your StackGuardian credentials and desired configuration:

```hcl
# StackGuardian Platform Credentials
api_key  = "sgu-your-api-key-here"
org_name = "your-org-name"

# Workflow Groups (environments)
workflow_groups = ["TeamX-Dev", "TeamX-Test", "TeamX-Staging", "TeamX-Prod"]

# Cloud Connectors
cloud_connectors = [{
  name                 = "aws-connector-1"
  connector_type       = "AWS_RBAC"
  role_arn            = "arn:aws:iam::123456789012:role/StackGuardianRole"
  aws_role_external_id = "your-org:random-string"
}]

# VCS Connectors
vcs_connectors = {
  vcs_github = {
    kind = "GITHUB_COM"
    name = "github-connector"
    config = [{
      github_creds = {
        githubCreds     = "username:personal_access_token"
        github_com_url  = "https://api.github.com"
        github_http_url = "https://github.com"
      }
    }]
  }
}

# Role Configuration
role_name     = "TeamX-Role"
template_list = ["opentofu-aws-vpc"]

# User Assignment
user_or_group = "user@example.com"
entity_type   = "EMAIL"
```

### 3. Initialize and Apply

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

## 📚 Module Documentation

### Core Modules

#### `stackguardian_workflow_group`
Creates workflow groups for organizing deployments by environment.

**Inputs:**
- `workflow_group_name` - Name of the workflow group
- `api_key` - StackGuardian API key
- `org_name` - StackGuardian organization name

**Outputs:**
- `workflow_groups` - Created workflow group name

#### `stackguardian_connector_cloud`
Sets up cloud provider connectors with various authentication methods.

**Supported Connector Types:**
- `AWS_STATIC` - AWS access key/secret
- `AWS_RBAC` - AWS role with external ID
- `AWS_OIDC` - AWS role with OIDC
- `AZURE_STATIC` - Azure service principal
- `AZURE_OIDC` - Azure with OIDC
- `GCP_STATIC` - GCP service account

**Key Inputs:**
- `cloud_connector_name` - Name of the connector
- `connector_type` - Type of connector (see above)
- `role_arn` - AWS role ARN (for AWS connectors)
- `role_external_id` - External ID for AWS RBAC

#### `stackguardian_connector_vcs`
Integrates with version control systems.

**Supported VCS Types:**
- `GITHUB_COM` - GitHub.com
- `GITLAB_COM` - GitLab.com
- `BITBUCKET_ORG` - Bitbucket.org

#### `stackguardian_role`
Creates custom roles with specific permissions.

**Key Inputs:**
- `role_name` - Name of the role
- `cloud_connectors` - List of accessible cloud connectors
- `vcs_connectors` - List of accessible VCS connectors
- `workflow_groups` - List of accessible workflow groups
- `template_list` - List of accessible templates

#### `stackguardian_role_assignment`
Assigns roles to users or groups.

**Key Inputs:**
- `user_or_group` - User email or group identifier
- `entity_type` - Either "EMAIL" or "GROUP"
- `role_name` - Role to assign

### Cloud Setup Modules

#### `aws_oidc`
Creates AWS IAM OIDC provider and role for StackGuardian.

#### `aws_rbac`
Sets up AWS IAM role with external ID for RBAC authentication.

#### `azure_oidc`
Configures Azure AD application and service principal for OIDC.

#### `gcp_oidc`
Sets up GCP workload identity federation for OIDC authentication.

## 🔧 Configuration Examples

### Multi-Environment Setup

```hcl
workflow_groups = [
  "frontend-dev",
  "frontend-staging",
  "frontend-prod",
  "backend-dev",
  "backend-staging",
  "backend-prod"
]
```

### Multiple Cloud Connectors

```hcl
cloud_connectors = [
  {
    name                 = "aws-dev"
    connector_type       = "AWS_RBAC"
    role_arn            = "arn:aws:iam::111111111111:role/StackGuardian-Dev"
    aws_role_external_id = "myorg:dev-12345"
  },
  {
    name                 = "aws-prod"
    connector_type       = "AWS_RBAC"
    role_arn            = "arn:aws:iam::222222222222:role/StackGuardian-Prod"
    aws_role_external_id = "myorg:prod-67890"
  }
]
```

### Multiple VCS Connectors

```hcl
vcs_connectors = {
  vcs_github = {
    kind = "GITHUB_COM"
    name = "github-main"
    config = [{
      github_creds = {
        githubCreds     = "username:personal_access_token"
        github_com_url  = "https://api.github.com"
        github_http_url = "https://github.com"
      }
    }]
  },
  vcs_gitlab = {
    kind = "GITLAB_COM"
    name = "gitlab-secondary"
    config = [{
      gitlab_creds = {
        gitlabCreds   = "username:personal_access_token"
        gitlabHttpUrl = "https://gitlab.com"
        gitlabApiUrl  = "https://gitlab.com/api/v4"
      }
    }]
  }
}
```

## 🔐 Security Best Practices

### API Key Management
- Store API keys in environment variables or secure secret management systems
- Never commit API keys to version control
- Use different API keys for different environments

### Cloud Connector Security
- Use RBAC or OIDC instead of static credentials when possible
- Follow principle of least privilege for IAM roles
- Regularly rotate access keys and external IDs
- Use separate AWS accounts/Azure subscriptions for different environments

### VCS Integration
- Use personal access tokens with minimal required scopes
- Regularly rotate VCS tokens
- Consider using organization-level tokens for team access

## 🚨 Troubleshooting

### Common Issues

**Provider Authentication Errors**
```bash
Error: Invalid API key or organization name
```
- Verify your `api_key` and `org_name` in terraform.tfvars
- Ensure the API key has sufficient permissions

**Cloud Connector Failures**
```bash
Error: Unable to assume role
```
- Check that the role ARN is correct
- Verify the external ID matches your StackGuardian organization
- Ensure the role trust policy allows StackGuardian to assume it

**VCS Connector Issues**
```bash
Error: Invalid VCS credentials
```
- Verify your VCS credentials format
- Check that tokens have required permissions
- Ensure URLs are correct for your VCS provider

### Debug Mode
Enable Terraform debug logging:
```bash
export TF_LOG=DEBUG
terraform apply
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- [StackGuardian Documentation](https://docs.stackguardian.io/)
- [StackGuardian Community](https://community.stackguardian.io/)
- [Terraform Provider Documentation](https://registry.terraform.io/providers/StackGuardian/stackguardian/latest/docs)

## 🏷️ Version Compatibility

| Module Version | StackGuardian Provider | Terraform Version |
|---------------|----------------------|------------------|
| 1.x.x         | 1.1.0-rc5           | >= 1.0           |

---

**Made with ❤️ by the StackGuardian Community**
