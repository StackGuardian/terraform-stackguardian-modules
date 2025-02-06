output "connector_vcs" {
  description = "Created VCS connector"
  value       = [for con in var.vcs_connectors : con.name]
}