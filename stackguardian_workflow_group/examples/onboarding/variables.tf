variable "org_name" {
  type = string
  description = "Organisation name in StackGuardian platform"
}
variable "api_key" {
  type = string
  description = "API key to authenticate to StackGuardian"
}
variable "workflow_groups" {
  type = list
  default = ["group-dev", "group-prod"]
}