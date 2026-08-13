variable "org_name" {
  type        = string
  description = "StackGuardian organization name used in permission paths."

  validation {
    condition     = length(trimspace(var.org_name)) > 0
    error_message = "org_name must not be empty."
  }
}

variable "workflow_groups" {
  type        = list(string)
  description = "Workflow groups granted to the role."

  validation {
    condition     = length(var.workflow_groups) > 0 && alltrue([for name in var.workflow_groups : length(trimspace(name)) > 0])
    error_message = "workflow_groups must contain at least one non-empty name."
  }
}

variable "cloud_connectors" {
  type        = list(string)
  description = "Cloud connector names granted to the role."

  validation {
    condition     = alltrue([for name in var.cloud_connectors : length(trimspace(name)) > 0])
    error_message = "cloud_connectors must contain only non-empty names."
  }
}

variable "vcs_connectors" {
  type        = list(string)
  description = "VCS connector names granted to the role."

  validation {
    condition     = alltrue([for name in var.vcs_connectors : length(trimspace(name)) > 0])
    error_message = "vcs_connectors must contain only non-empty names."
  }
}

variable "template_list" {
  type        = list(string)
  description = "Template names granted to the role."

  validation {
    condition     = alltrue([for name in var.template_list : length(trimspace(name)) > 0])
    error_message = "template_list must contain only non-empty names."
  }
}

variable "role_name" {
  type        = string
  description = "Name of the StackGuardian role."

  validation {
    condition     = length(trimspace(var.role_name)) > 0
    error_message = "role_name must not be empty."
  }
}
