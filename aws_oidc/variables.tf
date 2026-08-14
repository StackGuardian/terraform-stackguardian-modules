variable "aws_region" {
  type        = string
  description = "AWS region used by the provider."

  validation {
    condition     = can(regex("^[a-z]{2}(-gov)?-[a-z]+-\\d$", var.aws_region))
    error_message = "aws_region must be a valid AWS region."
  }
}

variable "iam_role_name" {
  type        = string
  description = "Name of the IAM role created for StackGuardian OIDC."
}

variable "stackguardian_org_name" {
  type        = string
  description = "StackGuardian organization name used in the OIDC subject."
}

variable "policy_arn" {
  type        = string
  description = "IAM policy attached to the OIDC role. ReadOnlyAccess is a permissive default."
  default     = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

variable "oidc_issuer_url" {
  type        = string
  description = "StackGuardian OIDC issuer URL."
  default     = "https://api.app.stackguardian.io"
}

variable "oidc_audience" {
  type        = string
  description = "OIDC audience accepted by the IAM role."
  default     = "https://api.app.stackguardian.io"
}

variable "oidc_thumbprint_list" {
  type        = list(string)
  description = "Trusted TLS certificate thumbprints for the OIDC issuer."
  default     = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]
}
