variable "subscription_id" {
  type = string
}

variable "client_id" {
  type = string
}

variable "client_secret" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "display_name" {
  type        = string
  description = "Display name for the Azure AD application"
}

variable "sg_org_name" {
  type        = string
  description = "StackGuardian organization name"
}