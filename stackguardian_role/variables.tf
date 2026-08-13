variable "org_name" {
  type        = string
  description = "StackGuardian organization name used in permission paths."
}

variable "workflow_groups" {
  type        = list(string)
  description = "Workflow groups granted to the role."
}

variable "cloud_connectors" {
  type        = list(string)
  description = "Cloud connector names granted to the role."
}

variable "vcs_connectors" {
  type        = list(string)
  description = "VCS connector names granted to the role."
}

variable "template_list" {
  type        = list(string)
  description = "Template names granted to the role."
}

variable "role_name" {
  type        = string
  description = "Name of the StackGuardian role."
}
