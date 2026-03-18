/*-------------------------------+
 | Cloud Function Outputs       |
 +-------------------------------*/
output "cloud_function_name" {
  description = "The name of the Cloud Function autoscaler"
  value       = google_cloudfunctions2_function.autoscaler.name
}

output "cloud_function_url" {
  description = "The URL of the Cloud Function autoscaler"
  value       = google_cloudfunctions2_function.autoscaler.url
}

/*-------------------------------+
 | Scheduler Outputs             |
 +-------------------------------*/
output "scheduler_name" {
  description = "The name of the Cloud Scheduler job"
  value       = google_cloud_scheduler_job.autoscaler.name
}

/*-------------------------------+
 | Service Account Outputs       |
 +-------------------------------*/
output "autoscaler_service_account_email" {
  description = "The email of the autoscaler service account"
  value       = google_service_account.autoscaler.email
}

/*-------------------------------+
 | Storage Outputs               |
 +-------------------------------*/
output "cooldown_bucket_name" {
  description = "The name of the GCS bucket used for cooldown state"
  value       = google_storage_bucket.cooldown_state.name
}
