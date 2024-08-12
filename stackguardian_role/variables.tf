variable "role_name" {
  type = string
  default = "StackGuardian-role-example"
}
variable "api_key" {
  type = string
  default = "sgu_6366Rj2tDHhoAf6M5zYA9"
}
variable "org_name" {
  type = string
  default = "wicked-hop"
}
variable "allowed_permissions" {
  type = any
  default = {
      "Permission-key-1" : "Permission-val-1",
      "Permission-key-2" : "Permission-val-2"
    }
}
variable "workflow_group" {
  type = string
  default = "StackGuardian-workflow-group-example"
  
}