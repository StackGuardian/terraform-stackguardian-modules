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
variable "allowed_permissions" {
  type = any
  default = {
      "Permission-key-1" : "Permission-val-1",
      "Permission-key-2" : "Permission-val-2"
    }
}
variable "workflow_groups" {
  type = list
  default = ["group-dev", "group-prod"]
}