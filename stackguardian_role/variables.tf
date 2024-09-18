variable "role_name" {
  type = string
}
variable "api_key" {
  type = string
}
variable "org_name" {
  type = string
}
variable "workflow_groups" {
  type = list
  default = ["group-dev", "group-prod"]
}
variable "allowed_permissions" {
  type = any
  default = {
      "Permission-key-1" : "Permission-val-1",
      "Permission-key-2" : "Permission-val-2"
    }
}