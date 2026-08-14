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
  description = "Workflow groups created by this root."
  default     = []

  validation {
    condition     = length(var.workflow_groups) == length(toset(var.workflow_groups)) && alltrue([for name in var.workflow_groups : length(trimspace(name)) > 0])
    error_message = "workflow_groups must contain unique, non-empty names."
  }
}

variable "cloud_connectors" {
  description = "Keyed cloud connectors. Terraform creates and registers the selected cloud identity; static kinds are legacy-only."
  type = map(object({
    kind                     = string
    allow_static_credentials = optional(bool)
    aws_region               = optional(string)
    iam_role_name            = optional(string)
    iam_user_name            = optional(string)
    policy_arn               = optional(string)
    aws_external_id          = optional(string)
    trusted_account_ids      = optional(list(string))
    azure_subscription_id    = optional(string)
    azure_tenant_id          = optional(string)
    application_display_name = optional(string)
    role_definition_name     = optional(string)
    gcp_project_id           = optional(string)
    gcp_service_account_id   = optional(string)
    gcp_workload_pool_id     = optional(string)
    gcp_provider_id          = optional(string)
    gcp_project_role         = optional(string)
  }))
  default = {}

  validation {
    condition     = alltrue([for name in keys(var.cloud_connectors) : can(regex("^[A-Za-z0-9][A-Za-z0-9 _.-]{0,99}$", name))])
    error_message = "cloud_connectors keys must be 1-100 character StackGuardian resource names."
  }

  validation {
    condition     = alltrue([for connector in values(var.cloud_connectors) : contains(["AWS_STATIC", "AWS_RBAC", "AWS_OIDC", "AZURE_STATIC", "AZURE_OIDC", "GCP_OIDC"], connector.kind)])
    error_message = "cloud_connectors[*].kind must be AWS_STATIC, AWS_RBAC, AWS_OIDC, AZURE_STATIC, AZURE_OIDC, or GCP_OIDC."
  }

  validation {
    condition = alltrue([for connector in values(var.cloud_connectors) :
      (connector.kind == "AWS_STATIC" && connector.allow_static_credentials == true &&
        (connector.aws_region == null || can(regex("^[a-z]{2}(-gov)?-[a-z]+-\\d$", connector.aws_region))) &&
        (connector.iam_user_name == null || can(regex("^[A-Za-z0-9][A-Za-z0-9 _.-]{0,99}$", connector.iam_user_name))) &&
      connector.iam_role_name == null && connector.policy_arn == null && connector.aws_external_id == null && connector.trusted_account_ids == null && connector.azure_subscription_id == null && connector.azure_tenant_id == null && connector.application_display_name == null && connector.role_definition_name == null && connector.gcp_project_id == null && connector.gcp_service_account_id == null && connector.gcp_workload_pool_id == null && connector.gcp_provider_id == null && connector.gcp_project_role == null) ||
      (connector.kind == "AWS_RBAC" && try(length(trimspace(connector.iam_role_name)) > 0, false) && try(length(trimspace(connector.aws_external_id)) > 0, false) &&
        (connector.aws_region == null || can(regex("^[a-z]{2}(-gov)?-[a-z]+-\\d$", connector.aws_region))) &&
        (connector.policy_arn == null || length(trimspace(connector.policy_arn)) > 0) &&
        (connector.trusted_account_ids == null || (length(connector.trusted_account_ids) == length(toset(connector.trusted_account_ids)) && alltrue([for account_id in connector.trusted_account_ids : can(regex("^\\d{12}$", account_id))]))) &&
      connector.allow_static_credentials == null && connector.iam_user_name == null && connector.azure_subscription_id == null && connector.azure_tenant_id == null && connector.application_display_name == null && connector.role_definition_name == null && connector.gcp_project_id == null && connector.gcp_service_account_id == null && connector.gcp_workload_pool_id == null && connector.gcp_provider_id == null && connector.gcp_project_role == null) ||
      (connector.kind == "AWS_OIDC" && try(can(regex("^[A-Za-z0-9][A-Za-z0-9 _.-]{0,99}$", connector.iam_role_name)), false) &&
        (connector.aws_region == null || can(regex("^[a-z]{2}(-gov)?-[a-z]+-\\d$", connector.aws_region))) &&
        (connector.policy_arn == null || length(trimspace(connector.policy_arn)) > 0) &&
      connector.allow_static_credentials == null && connector.iam_user_name == null && connector.aws_external_id == null && connector.trusted_account_ids == null && connector.azure_subscription_id == null && connector.azure_tenant_id == null && connector.application_display_name == null && connector.role_definition_name == null && connector.gcp_project_id == null && connector.gcp_service_account_id == null && connector.gcp_workload_pool_id == null && connector.gcp_provider_id == null && connector.gcp_project_role == null) ||
      (connector.kind == "AZURE_STATIC" && connector.allow_static_credentials == true && try(can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", connector.azure_subscription_id)), false) && try(can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", connector.azure_tenant_id)), false) &&
        (connector.application_display_name == null || can(regex("^[A-Za-z0-9][A-Za-z0-9 _.-]{0,99}$", connector.application_display_name))) &&
        (connector.role_definition_name == null || length(trimspace(connector.role_definition_name)) > 0) &&
      connector.aws_region == null && connector.iam_role_name == null && connector.iam_user_name == null && connector.policy_arn == null && connector.aws_external_id == null && connector.trusted_account_ids == null && connector.gcp_project_id == null && connector.gcp_service_account_id == null && connector.gcp_workload_pool_id == null && connector.gcp_provider_id == null && connector.gcp_project_role == null) ||
      (connector.kind == "AZURE_OIDC" && try(can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", connector.azure_subscription_id)), false) && try(can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", connector.azure_tenant_id)), false) &&
        (connector.application_display_name == null || can(regex("^[A-Za-z0-9][A-Za-z0-9 _.-]{0,99}$", connector.application_display_name))) &&
        (connector.role_definition_name == null || length(trimspace(connector.role_definition_name)) > 0) &&
      connector.allow_static_credentials == null && connector.aws_region == null && connector.iam_role_name == null && connector.iam_user_name == null && connector.policy_arn == null && connector.aws_external_id == null && connector.trusted_account_ids == null && connector.gcp_project_id == null && connector.gcp_service_account_id == null && connector.gcp_workload_pool_id == null && connector.gcp_provider_id == null && connector.gcp_project_role == null) ||
      (connector.kind == "GCP_OIDC" && try(can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", connector.gcp_project_id)), false) && try(length(trimspace(connector.gcp_service_account_id)) > 0, false) && try(length(trimspace(connector.gcp_workload_pool_id)) > 0, false) && try(length(trimspace(connector.gcp_provider_id)) > 0, false) &&
        (connector.gcp_project_role == null || length(trimspace(connector.gcp_project_role)) > 0) &&
      connector.allow_static_credentials == null && connector.aws_region == null && connector.iam_role_name == null && connector.iam_user_name == null && connector.policy_arn == null && connector.aws_external_id == null && connector.trusted_account_ids == null && connector.azure_subscription_id == null && connector.azure_tenant_id == null && connector.application_display_name == null && connector.role_definition_name == null)
    ])
    error_message = "Each cloud connector must provide only the properties valid for its kind, including required IDs and static credential acknowledgement."
  }
}

variable "vcs_connectors" {
  description = "Keyed VCS connector configuration. Credentials are sensitive and persist in Terraform state."
  sensitive   = true
  type = map(object({
    kind = string
    name = string
    github = optional(object({
      githubCreds     = string
      github_com_url  = optional(string)
      github_http_url = optional(string)
    }))
    gitlab = optional(object({
      gitlabCreds   = string
      gitlabHttpUrl = optional(string)
      gitlabApiUrl  = optional(string)
    }))
    bitbucket = optional(object({
      bitbucket_creds = string
    }))
  }))
  default = {}

  validation {
    condition     = alltrue([for name, connector in var.vcs_connectors : can(regex("^[A-Za-z0-9][A-Za-z0-9 _.-]{0,99}$", name)) && connector.name == name])
    error_message = "vcs_connectors keys must be resource names and match the name required by the unchanged VCS connector module."
  }

  validation {
    condition = alltrue([for connector in values(var.vcs_connectors) :
      (connector.kind == "GITHUB_COM" && connector.github != null && connector.gitlab == null && connector.bitbucket == null && length(trimspace(connector.github.githubCreds)) > 0) ||
      (connector.kind == "GITLAB_COM" && connector.gitlab != null && connector.github == null && connector.bitbucket == null && length(trimspace(connector.gitlab.gitlabCreds)) > 0) ||
      (connector.kind == "BITBUCKET_ORG" && connector.bitbucket != null && connector.github == null && connector.gitlab == null && length(trimspace(connector.bitbucket.bitbucket_creds)) > 0)
    ])
    error_message = "Each VCS connector must have exactly one matching GitHub, GitLab, or Bitbucket credential object with non-empty credentials."
  }
}

variable "roles" {
  description = "Keyed StackGuardian roles and their resource scopes."
  type = map(object({
    workflow_groups  = optional(list(string), [])
    cloud_connectors = optional(list(string), [])
    vcs_connectors   = optional(list(string), [])
    template_list    = optional(list(string), [])
  }))
  default = {}

  validation {
    condition = alltrue([for name, role in var.roles :
      can(regex("^[A-Za-z0-9][A-Za-z0-9 _.-]{0,99}$", name)) &&
      length(role.workflow_groups) == length(toset(role.workflow_groups)) &&
      length(role.cloud_connectors) == length(toset(role.cloud_connectors)) &&
      length(role.vcs_connectors) == length(toset(role.vcs_connectors)) &&
      length(role.template_list) == length(toset(role.template_list)) &&
      alltrue([for reference in concat(role.workflow_groups, role.cloud_connectors, role.vcs_connectors, role.template_list) : length(trimspace(reference)) > 0]) &&
      length(concat(role.workflow_groups, role.cloud_connectors, role.vcs_connectors, role.template_list)) > 0
    ])
    error_message = "Each role key must be a resource name and each role must have at least one unique, non-empty workflow group, connector, or template reference."
  }
}

variable "subjects" {
  description = "Keyed local-email, qualified SSO-email, or SSO-group subjects and their assigned roles."
  type = map(object({
    entity_type = optional(string, "EMAIL")
    roles       = list(string)
  }))
  default = {}

  validation {
    condition = alltrue([for subject, assignment in var.subjects :
      can(regex("^([^/@\\s]+/[^/\\s]+|[^@\\s]+@[^@\\s]+\\.[^@\\s]+)$", subject)) &&
      contains(["EMAIL", "GROUP"], assignment.entity_type) &&
      length(assignment.roles) > 0 && length(assignment.roles) == length(toset(assignment.roles)) &&
      alltrue([for role in assignment.roles : can(regex("^[A-Za-z0-9][A-Za-z0-9 _.-]{0,99}$", role))])
    ])
    error_message = "Each subject must be a local email or qualified SSO subject with a valid entity_type and a non-empty, duplicate-free role list."
  }
}
