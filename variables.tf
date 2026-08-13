variable "stackguardian_api_key" {
  type        = string
  description = "StackGuardian API key used by the root provider configuration."
  sensitive   = true

  validation {
    condition     = can(regex("^sgu_[A-Za-z0-9]+$", var.stackguardian_api_key))
    error_message = "stackguardian_api_key must start with sgu_ followed by alphanumeric characters."
  }
}

variable "stackguardian_org_name" {
  type        = string
  description = "StackGuardian organization name."

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9_-]{0,49}$", var.stackguardian_org_name))
    error_message = "stackguardian_org_name must be 1-50 letters, numbers, underscores, or hyphens."
  }
}

variable "stackguardian_api_uri" {
  type        = string
  description = "StackGuardian API endpoint."
  default     = "https://api.app.stackguardian.io"

  validation {
    condition     = can(regex("^https://[^/]+(?:/.*)?$", var.stackguardian_api_uri))
    error_message = "stackguardian_api_uri must be an HTTPS URL."
  }
}

variable "workflow_groups" {
  type        = list(string)
  description = "Workflow groups created and granted to the role."

  validation {
    condition     = length(var.workflow_groups) > 0 && alltrue([for name in var.workflow_groups : length(trimspace(name)) > 0])
    error_message = "workflow_groups must contain at least one non-empty name."
  }
}

variable "cloud_connectors" {
  description = "Cloud connectors managed by the root stack. Static credentials are stored in Terraform state."
  type = list(object({
    name                    = string
    kind                    = string
    aws_access_key_id       = optional(string)
    aws_secret_access_key   = optional(string)
    aws_region              = optional(string)
    azure_tenant_id         = optional(string)
    azure_subscription_id   = optional(string)
    azure_client_id         = optional(string)
    azure_client_secret     = optional(string)
    aws_role_arn            = optional(string)
    aws_external_id         = optional(string)
    gcp_config_file_content = optional(string)
  }))
  sensitive = true

  validation {
    condition     = alltrue([for connector in var.cloud_connectors : contains(["AWS_STATIC", "AWS_RBAC", "AWS_OIDC", "AZURE_STATIC", "AZURE_OIDC", "GCP_OIDC"], connector.kind)])
    error_message = "cloud_connectors[*].kind must be AWS_STATIC, AWS_RBAC, AWS_OIDC, AZURE_STATIC, AZURE_OIDC, or GCP_OIDC."
  }

  validation {
    condition = alltrue([for connector in var.cloud_connectors :
      (connector.kind != "AWS_STATIC" || (try(length(trimspace(connector.aws_access_key_id)) > 0, false) && try(length(trimspace(connector.aws_secret_access_key)) > 0, false) && try(can(regex("^[a-z]{2}(-gov)?-[a-z]+-\\d$", connector.aws_region)), false))) &&
      (connector.kind != "AWS_RBAC" || (try(can(regex("^arn:aws[a-z-]*:iam::\\d{12}:role/.+$", connector.aws_role_arn)), false) && try(length(trimspace(connector.aws_external_id)) > 0, false))) &&
      (connector.kind != "AWS_OIDC" || try(can(regex("^arn:aws[a-z-]*:iam::\\d{12}:role/.+$", connector.aws_role_arn)), false)) &&
      (connector.kind != "AZURE_STATIC" || (try(can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", connector.azure_tenant_id)), false) && try(can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", connector.azure_subscription_id)), false) && try(can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", connector.azure_client_id)), false) && try(length(trimspace(connector.azure_client_secret)) > 0, false))) &&
      (connector.kind != "AZURE_OIDC" || (try(can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", connector.azure_tenant_id)), false) && try(can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", connector.azure_subscription_id)), false) && try(can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", connector.azure_client_id)), false))) &&
      (connector.kind != "GCP_OIDC" || try(length(trimspace(connector.gcp_config_file_content)) > 0, false))
    ])
    error_message = "Each cloud connector must supply valid credentials required by its kind."
  }
}

variable "vcs_connectors" {
  description = "VCS connector configuration. Credentials are sensitive and persist in Terraform state."
  sensitive   = true
  type = map(object({
    kind = string
    name = string
    github = optional(object({
      githubCreds     = string
      github_com_url  = optional(string, "https://api.github.com")
      github_http_url = optional(string, "https://github.com")
    }))
    gitlab = optional(object({
      gitlabCreds   = string
      gitlabHttpUrl = optional(string, "https://gitlab.com")
      gitlabApiUrl  = optional(string, "https://gitlab.com/api/v4")
    }))
    bitbucket = optional(object({
      bitbucket_creds = string
    }))
  }))
  default = {}

  validation {
    condition = alltrue([for connector in values(var.vcs_connectors) :
      (connector.kind == "GITHUB_COM" && connector.github != null && connector.gitlab == null && connector.bitbucket == null) ||
      (connector.kind == "GITLAB_COM" && connector.gitlab != null && connector.github == null && connector.bitbucket == null) ||
      (connector.kind == "BITBUCKET_ORG" && connector.bitbucket != null && connector.github == null && connector.gitlab == null)
    ])
    error_message = "Each VCS connector must have exactly one matching GitHub, GitLab, or Bitbucket credential object."
  }
}

variable "role_name" {
  type        = string
  description = "StackGuardian role name."

  validation {
    condition     = length(trimspace(var.role_name)) > 0
    error_message = "role_name must not be empty."
  }
}

variable "template_list" {
  type        = list(string)
  description = "Templates granted to the StackGuardian role."

  validation {
    condition     = length(var.template_list) > 0 && alltrue([for name in var.template_list : length(trimspace(name)) > 0])
    error_message = "template_list must contain at least one non-empty template name."
  }
}

variable "subject" {
  type        = string
  description = "Local email or qualified SSO email/group subject receiving the role."

  validation {
    condition     = can(regex("^([^/@\\s]+/[^/\\s]+|[^@\\s]+@[^@\\s]+\\.[^@\\s]+)$", var.subject))
    error_message = "subject must be a local email or a qualified SSO subject in provider/value format."
  }
}

variable "entity_type" {
  type        = string
  description = "Type of StackGuardian assignment subject: EMAIL or GROUP."

  validation {
    condition     = contains(["EMAIL", "GROUP"], var.entity_type)
    error_message = "entity_type must be EMAIL or GROUP."
  }
}
