/*-----------------------+
 | MIG Outputs            |
 +-----------------------*/
output "mig_name" {
  description = "The name of the Managed Instance Group"
  value       = google_compute_region_instance_group_manager.this.name
}

output "mig_self_link" {
  description = "The self link of the Managed Instance Group"
  value       = google_compute_region_instance_group_manager.this.self_link
}

output "instance_template_self_link" {
  description = "The self link of the Instance Template"
  value       = google_compute_instance_template.this.self_link
}

/*-----------------------+
 | IAM Outputs            |
 +-----------------------*/
output "service_account_email" {
  description = "The email of the GCP service account for runner instances"
  value       = google_service_account.runner.email
}

output "aws_s3_access_role_arn" {
  description = "The ARN of the AWS IAM role for S3 access via Workload Identity Federation"
  value       = aws_iam_role.gcp_s3_access.arn
}

/*-----------------------+
 | Cloud NAT Outputs      |
 +-----------------------*/
output "cloud_nat_ip" {
  description = "The Cloud NAT IP addresses (only when create_cloud_nat = true)"
  value       = local.create_cloud_nat ? google_compute_router_nat.this[0].nat_ips : null
}
