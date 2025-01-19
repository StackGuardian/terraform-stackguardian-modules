variable "api_key" {
  type = string
  description = "value of the api key for the StackGuardian platform"
}
variable "org_name" {
  type = string
  description = "name of the organization on StackGuardian that you want to work with"
}
variable "user_id" {
  type = string
  description = "email id for the individual" 
}
variable "role_name" {
  type = string
  description = "Role that should be assigned to the User or group"
}

