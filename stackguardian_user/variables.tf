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
  #Format: sso-auth/email (email in SSO), sso-auth/group-id (Group in SSO), email (Email via local login)
  #Example: "stackguardian-1/user@sg.com" or "stackguardian-1/9djhd38cniwje9jde" or "user@org.com"
}
variable "role_name" {
  type = string
  description = "Role that should be assigned to the User or group"
}
