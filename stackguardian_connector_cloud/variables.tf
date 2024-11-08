variable "connector_type" {
  type = string
  # AWS_STATIC, AWS_RBAC, AWS_OIDC, AZURE_STATIC, AZURE_OIDC, GCP_STATIC
}

variable "resource_name" {
 type = string
  description = "Name of the Cloud connector"
}
variable "api_key" {
  type = string
  description = "API key to authenticate to StackGuardian"
}
variable "org_name" {
  type = string
  description = "Organisation name in StackGuardian platform"
}


################
# AWS_STATIC Credentials
################

variable "aws_access_key_id" {
  type = string
  description = "AWS ACCESS Key ID"
  default = ""
}
variable "aws_secret_access_key" {
  type = string
  description = "AWS ACCESS Key Secret"
  default = ""
}
variable "aws_default_region" {
  type = string
  description = "AWS Default Region for Connector"
  default = ""
}

################
# AZURE_STATIC Credentials
################


variable "armTenantId" {
  type = string
  description = "Azure Tenant ID"
  default = ""
}
variable "armSubscriptionId" {
  type = string
  description = "Subscription ID"
  default = ""
}
variable "armClientId" {
  type = string
  description = "Client ID for Enterprise App"
  default = ""
}
variable "armClientSecret" {
  type = string
  description = "Client Secret for Enterprise App"
  default = ""
}