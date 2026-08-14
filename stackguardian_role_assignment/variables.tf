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
  description = "Subject type: EMAIL or GROUP."

  validation {
    condition     = contains(["EMAIL", "GROUP"], var.entity_type)
    error_message = "entity_type must be EMAIL or GROUP."
  }
}

variable "role_name" {
  type        = string
  description = "Single StackGuardian role assigned to the subject."
}
