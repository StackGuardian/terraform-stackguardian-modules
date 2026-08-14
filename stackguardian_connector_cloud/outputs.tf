output "connector_name" {
  description = "Created cloud connector name."
  value       = stackguardian_connector.cloud.resource_name
}

output "connector_kind" {
  description = "Created cloud connector kind."
  value       = var.connector_kind
}

output "connector_id" {
  description = "Provider-computed cloud connector ID."
  value       = stackguardian_connector.cloud.id
}
