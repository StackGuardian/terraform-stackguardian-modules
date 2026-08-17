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
  default     = []

  validation {
    condition     = length(var.workflow_groups) == length(toset(var.workflow_groups)) && alltrue([for name in var.workflow_groups : length(trimspace(name)) > 0])
    error_message = "workflow_groups must contain unique, non-empty names."
  }
}

variable "cloud_connectors" {
  type        = list(string)
  description = "Cloud connector names granted to the role."
  default     = []

  validation {
    condition     = length(var.cloud_connectors) == length(toset(var.cloud_connectors)) && alltrue([for name in var.cloud_connectors : length(trimspace(name)) > 0])
    error_message = "cloud_connectors must contain unique, non-empty names."
  }
}

variable "vcs_connectors" {
  type        = list(string)
  description = "VCS connector names granted to the role."
  default     = []

  validation {
    condition     = length(var.vcs_connectors) == length(toset(var.vcs_connectors)) && alltrue([for name in var.vcs_connectors : length(trimspace(name)) > 0])
    error_message = "vcs_connectors must contain unique, non-empty names."
  }
}

variable "template_list" {
  type        = list(string)
  description = "Template names granted to the role."
  default     = []

  validation {
    condition     = length(var.template_list) == length(toset(var.template_list)) && alltrue([for name in var.template_list : length(trimspace(name)) > 0])
    error_message = "template_list must contain unique, non-empty names."
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
