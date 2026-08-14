output "connector_vcs" {
  description = "Created VCS connector"
  value       = [for connector in values(var.vcs_connectors) : connector.name]
}
