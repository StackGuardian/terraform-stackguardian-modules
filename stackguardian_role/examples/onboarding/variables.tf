variable "role_name" {
  type = string
  default = "stackGuardian-Role"
}
variable "api_key" {
  type = string
  default = ""
}
variable "org_name" {
  type = string
  default = ""
}
variable "workflow_groups" {
  type = list
  default = ["group-dev", "group-prod"]
}