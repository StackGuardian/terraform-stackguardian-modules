variable "aws_region" {
  type        = string
  description = "AWS region used by the provider."
  default     = "eu-central-1"

  validation {
    condition     = can(regex("^[a-z]{2}(-gov)?-[a-z]+-\\d$", var.aws_region))
    error_message = "aws_region must be a valid AWS region."
  }
}

variable "iam_role_name" {
  type        = string
  description = "Name of the IAM role created for StackGuardian."
}

variable "role_external_id" {
  type        = string
  description = "External ID required by the StackGuardian AWS RBAC connector."
  sensitive   = true

  validation {
    condition     = length(trimspace(var.role_external_id)) > 0
    error_message = "role_external_id must not be empty."
  }
}

variable "policy_arn" {
  type        = string
  description = "IAM policy attached to the StackGuardian role. ReadOnlyAccess is a permissive default."
  default     = "arn:aws:iam::aws:policy/ReadOnlyAccess"

  validation {
    condition     = can(regex("^arn:aws[a-z-]*:iam::(aws|\\d{12}):policy/.+$", var.policy_arn))
    error_message = "policy_arn must be a valid IAM policy ARN."
  }
}

variable "trusted_account_ids" {
  type        = list(string)
  description = "AWS account IDs trusted to assume the role."
  default     = ["476299211833", "163602625436"]

  validation {
    condition     = length(var.trusted_account_ids) > 0 && alltrue([for account_id in var.trusted_account_ids : can(regex("^\\d{12}$", account_id))])
    error_message = "trusted_account_ids must contain one or more 12-digit AWS account IDs."
  }
}
