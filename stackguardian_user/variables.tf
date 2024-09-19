variable "org_name" {
  type = string
  description = "Organisation name in StackGuardian platform"
}
variable "api_key" {
  type = string
  description = "API key to authenticate to StackGuardian"
}
variable "group_or_user" {
  type = string
  description = "Group or User that should be onboarded"
}
variable "role_name" {
  type = string
  description = "Role that should be assigned to the User or group"
}
