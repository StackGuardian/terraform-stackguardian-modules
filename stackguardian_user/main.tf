resource "stackguardian_role_assignment" "sg-user" {
  user_id     = var.user_id
  entity_type = "EMAIL"
  role        = var.role_name
}
