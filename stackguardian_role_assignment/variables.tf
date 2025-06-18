variable "api_key" {
  type        = string
  description = "value of the api key for the StackGuardian platform"
}
variable "org_name" {
  type        = string
  description = "name of the organization on StackGuardian that you want to work with"
}
variable "user_or_group" {
  type        = string
  description = "Group or User that should be onboarded"
  #Format: sso-auth/email (email in SSO), sso-auth/group-id (Group in SSO), email (Email via local login)
  #Example: "stackguardian-1/user@stackguardian.com" or "stackguardian-1/9djhd38cniwje9jde" or "user@stackguardian.com"
}
variable "entity_type" {
  type        = string
  description = "Type of entity that should be onboarded"
  #Valid values: "EMAIL" or "GROUP"
}

variable "role_name" {
  type        = string
  description = "Role that will be assigned to the User or group"
}


