variable "subscription_id" {
  type        = string
  description = "Azure subscription ID where the Contributor assignment is created."

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "subscription_id must be a UUID."
  }
}

variable "client_id" {
  type        = string
  description = "Client ID Terraform uses to manage Azure resources."

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.client_id))
    error_message = "client_id must be a UUID."
  }
}

variable "client_secret" {
  type        = string
  description = "Client secret Terraform uses to manage Azure resources."
  sensitive   = true

  validation {
    condition     = length(trimspace(var.client_secret)) > 0
    error_message = "client_secret must not be empty."
  }
}

variable "tenant_id" {
  type        = string
  description = "Azure tenant ID."

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.tenant_id))
    error_message = "tenant_id must be a UUID."
  }
}

variable "application_display_name" {
  type        = string
  description = "Display name for the Entra application."
}

variable "role_definition_name" {
  type        = string
  description = "Azure subscription role assigned to the created service principal. Contributor is a high-privilege default."
  default     = "Contributor"
}

variable "service_principal_password_end_date_relative" {
  type        = string
  description = "Finite lifetime for the generated service principal secret."
  default     = "8760h"

  validation {
    condition     = can(regex("^[1-9][0-9]*h$", var.service_principal_password_end_date_relative))
    error_message = "service_principal_password_end_date_relative must be a positive number of hours."
  }
}
