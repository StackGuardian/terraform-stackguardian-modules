output "user" {
  description = "User or group assigned to the roles."
  value       = var.subject
}

output "roles" {
  description = "Roles assigned to the user or group."
  value       = var.roles
}
