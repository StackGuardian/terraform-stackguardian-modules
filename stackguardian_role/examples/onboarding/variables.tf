variable "role_name" {
  type = string
  default = "StackGuardian-role-example"
}
#variable "api_key" {
  #type = string
  #default = "value"
#}
variable "org_name" {
  type = string
  default = "value"
}
variable "allowed_permissions" {
  type = any
  default = {
      "Permission-key-1" : "Permission-val-1",
      "Permission-key-2" : "Permission-val-2"
    }
}
variable "wfGrp" {
  type = list
  default = ["StackGuardian-workflow-group-example"]
}