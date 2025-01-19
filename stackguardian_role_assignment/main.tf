resource "stackguardian_role_assignment" "sg-user" {
  user_id     = var.user_or_group
  entity_type = var.entity_type
  role        = var.role_name
}
