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
  description = "Cloud connectors managed by the root stack. Terraform creates and registers the selected cloud identity; static kinds are legacy-only."
  type = list(object({
    name                     = string
    kind                     = string
    iam_role_name            = optional(string)
    iam_user_name            = optional(string)
    policy_arn               = optional(string, "arn:aws:iam::aws:policy/ReadOnlyAccess")
    aws_external_id          = optional(string)
    trusted_account_ids      = optional(list(string))
    role_definition_name     = optional(string, "Contributor")
    application_display_name = optional(string)
    gcp_service_account_id   = optional(string)
    gcp_workload_pool_id     = optional(string)
    gcp_provider_id          = optional(string)
    gcp_project_role         = optional(string, "roles/owner")
    allow_static_credentials = optional(bool, false)
  }))
  validation {
    condition     = alltrue([for connector in var.cloud_connectors : contains(["AWS_STATIC", "AWS_RBAC", "AWS_OIDC", "AZURE_STATIC", "AZURE_OIDC", "GCP_OIDC"], connector.kind)])
    error_message = "cloud_connectors[*].kind must be AWS_STATIC, AWS_RBAC, AWS_OIDC, AZURE_STATIC, AZURE_OIDC, or GCP_OIDC."
  }

  validation {
    condition     = alltrue([for connector in var.cloud_connectors : !contains(["AWS_STATIC", "AZURE_STATIC"], connector.kind) || connector.allow_static_credentials])
    error_message = "AWS_STATIC and AZURE_STATIC connectors require allow_static_credentials = true. Use AWS_RBAC, AWS_OIDC, AZURE_OIDC, or another non-static connector kind instead."
  }

  validation {
    condition = alltrue([for connector in var.cloud_connectors :
      (connector.kind != "AWS_RBAC" || try(length(trimspace(connector.iam_role_name)) > 0, false) && try(length(trimspace(connector.aws_external_id)) > 0, false)) &&
      (connector.kind != "AWS_OIDC" || try(length(trimspace(connector.iam_role_name)) > 0, false)) &&
      (connector.kind != "GCP_OIDC" || (try(length(trimspace(connector.gcp_service_account_id)) > 0, false) && try(length(trimspace(connector.gcp_workload_pool_id)) > 0, false) && try(length(trimspace(connector.gcp_provider_id)) > 0, false)))
    ])
    error_message = "Each connector must provide the identity names required by its kind; OIDC connector IDs are created by Terraform."
  }
}

variable "aws_region" {
  type        = string
  description = "AWS region used to create AWS identities. Authentication uses the standard AWS credential chain, including AWS CLI login."
  default     = "eu-central-1"
}

variable "azure_subscription_id" {
  type        = string
  description = "Azure subscription used to create Azure identities. Authentication uses the Azure CLI login."
  default     = null
}

variable "azure_tenant_id" {
  type        = string
  description = "Azure tenant used to create Entra identities. Authentication uses the Azure CLI login."
  default     = null
}

variable "gcp_project_id" {
  type        = string
  description = "Google Cloud project used to create workload identity resources. Authentication uses gcloud application-default credentials."
  default     = null
}

variable "gcp_region" {
  type        = string
  description = "Google Cloud region used by the Google provider."
  default     = "europe-west3"
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
