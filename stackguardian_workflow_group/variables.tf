variable "workflow_group_name" {
  type        = string
  description = "Workflow group name."

  validation {
    condition     = length(trimspace(var.workflow_group_name)) > 0
    error_message = "workflow_group_name must not be empty."
  }
}
