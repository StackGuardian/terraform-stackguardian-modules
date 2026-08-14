output "user" {
  description = "User or group assigned to the role."
  value       = var.subject
}
output "role" {
  description = "Role assigned to the user or group."
  value       = var.role_name
}
