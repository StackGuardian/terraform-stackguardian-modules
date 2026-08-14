variable "subject" {
  type        = string
  description = "Local email or qualified SSO email/group subject receiving the roles."

  validation {
    condition     = can(regex("^([^/@\\s]+/[^/\\s]+|[^@\\s]+@[^@\\s]+\\.[^@\\s]+)$", var.subject))
    error_message = "subject must be a local email or a qualified SSO subject in provider/value format."
  }
}

variable "entity_type" {
  type        = string
  description = "Subject type: EMAIL or GROUP."
  default     = "EMAIL"

  validation {
    condition     = contains(["EMAIL", "GROUP"], var.entity_type)
    error_message = "entity_type must be EMAIL or GROUP."
  }
}

variable "roles" {
  type        = list(string)
  description = "StackGuardian roles assigned to the subject."

  validation {
    condition     = length(var.roles) > 0 && length(var.roles) == length(toset(var.roles)) && alltrue([for role in var.roles : length(trimspace(role)) > 0])
    error_message = "roles must contain one or more unique, non-empty role names."
  }
}
