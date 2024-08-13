variable "vcs_connector" {
  type = string
}
variable "gitcreds" {
  type = string
}
variable "api_key" {
  type = string
  description = "API key to authenticate to StackGuardian"
}
variable "org_name" {
  type = string
  description = "Organisation name in StackGuardian platform"
}