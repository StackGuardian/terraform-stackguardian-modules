variable "subscription_id" {
  type        = string
  description = "Azure subscription ID where the role assignment is created."

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "subscription_id must be a UUID."
  }
}

variable "tenant_id" {
  type        = string
  description = "Azure tenant ID."
}

variable "application_display_name" {
  type        = string
  description = "Display name for the Entra application."
}

variable "stackguardian_org_name" {
  type        = string
  description = "StackGuardian organization name used in the default OIDC subject."
}

variable "role_definition_name" {
  type        = string
  description = "Azure subscription role assigned to the created service principal. Contributor is a high-privilege default."
  default     = "Contributor"
}

variable "oidc_issuer" {
  type        = string
  description = "OIDC issuer URI."
  default     = "https://api.app.stackguardian.io"
}

variable "oidc_audiences" {
  type        = list(string)
  description = "OIDC audiences accepted by the federated credential."
  default     = ["https://api.app.stackguardian.io"]
}

variable "oidc_subject" {
  type        = string
  description = "OIDC subject accepted by the federated credential."
  default     = null
}

variable "federated_credential_name" {
  type        = string
  description = "Display name of the federated identity credential."
  default     = "sg-federated-identity"
}
