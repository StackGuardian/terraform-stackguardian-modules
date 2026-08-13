variable "project_id" {
  type        = string
  description = "Google Cloud project ID."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be a valid Google Cloud project ID."
  }
}

variable "region" {
  type        = string
  description = "Google Cloud region for the provider."
}

variable "stackguardian_org_id" {
  type        = string
  description = "StackGuardian organization ID used in the default OIDC subject."

  validation {
    condition     = length(trimspace(var.stackguardian_org_id)) > 0
    error_message = "stackguardian_org_id must not be empty."
  }
}

variable "oidc_subject" {
  type        = string
  description = "Exact StackGuardian OIDC subject accepted by workload identity."
  default     = null

  validation {
    condition     = var.oidc_subject == null || can(regex("^/orgs/[^/\\s]+$", var.oidc_subject))
    error_message = "oidc_subject must use the /orgs/<stackguardian_org_id> format."
  }
}

variable "service_account_id" {
  type        = string
  description = "Service account ID."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.service_account_id))
    error_message = "service_account_id must be 6-30 lowercase letters, digits, or hyphens."
  }
}

variable "workload_identity_pool_id" {
  type        = string
  description = "Workload identity pool ID."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{3,31}$", var.workload_identity_pool_id))
    error_message = "workload_identity_pool_id must be 4-32 lowercase letters, digits, or hyphens."
  }
}

variable "workload_identity_pool_provider_id" {
  type        = string
  description = "Workload identity pool provider ID."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{3,31}$", var.workload_identity_pool_provider_id))
    error_message = "workload_identity_pool_provider_id must be 4-32 lowercase letters, digits, or hyphens."
  }
}

variable "workload_identity_pool_display_name" {
  type        = string
  description = "Display name of the workload identity pool provider."
}

variable "oidc_issuer_uri" {
  type        = string
  description = "StackGuardian OIDC issuer URI."
  default     = "https://api.app.stackguardian.io"
}

variable "oidc_allowed_audiences" {
  type        = list(string)
  description = "OIDC audiences allowed by workload identity."
  default     = ["https://api.app.stackguardian.io"]
}

variable "project_role" {
  type        = string
  description = "Project role granted to the StackGuardian service account. roles/owner is a high-privilege default."
  default     = "roles/owner"
}
