variable "connector_name" {
  type        = string
  description = "Name of the cloud connector."

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9 _.-]{0,99}$", var.connector_name))
    error_message = "connector_name must be 1-100 characters and start with a letter or number."
  }
}

variable "connector_kind" {
  type        = string
  description = "Cloud connector kind."

  validation {
    condition     = contains(["AWS_STATIC", "AWS_RBAC", "AWS_OIDC", "AZURE_STATIC", "AZURE_OIDC", "GCP_OIDC"], var.connector_kind)
    error_message = "connector_kind must be AWS_STATIC, AWS_RBAC, AWS_OIDC, AZURE_STATIC, AZURE_OIDC, or GCP_OIDC."
  }
}

variable "aws_access_key_id" {
  type        = string
  description = "AWS access key ID for an AWS_STATIC connector."
  default     = null
  sensitive   = true
}

variable "aws_secret_access_key" {
  type        = string
  description = "AWS secret access key for an AWS_STATIC connector."
  default     = null
  sensitive   = true
}

variable "aws_region" {
  type        = string
  description = "AWS region for an AWS_STATIC connector."
  default     = null

  validation {
    condition     = var.aws_region == null || can(regex("^[a-z]{2}(-gov)?-[a-z]+-\\d$", var.aws_region))
    error_message = "aws_region must be a valid AWS region."
  }
}

variable "azure_tenant_id" {
  type        = string
  description = "Azure tenant ID for an Azure connector."
  default     = null
}

variable "azure_subscription_id" {
  type        = string
  description = "Azure subscription ID for an Azure connector."
  default     = null
}

variable "azure_client_id" {
  type        = string
  description = "Azure application client ID for an Azure connector."
  default     = null
}

variable "azure_client_secret" {
  type        = string
  description = "Azure application secret for an AZURE_STATIC connector."
  default     = null
  sensitive   = true
}

variable "aws_role_arn" {
  type        = string
  description = "AWS role ARN for AWS_RBAC or AWS_OIDC connectors."
  default     = null

  validation {
    condition     = var.aws_role_arn == null || can(regex("^arn:aws[a-z-]*:iam::\\d{12}:role/.+$", var.aws_role_arn))
    error_message = "aws_role_arn must be a valid IAM role ARN."
  }
}

variable "aws_external_id" {
  type        = string
  description = "External ID for an AWS_RBAC connector."
  default     = null
  sensitive   = true
}

variable "gcp_config_file_content" {
  type        = string
  description = "Google external-account configuration content for a GCP_OIDC connector."
  default     = null
  sensitive   = true
}
