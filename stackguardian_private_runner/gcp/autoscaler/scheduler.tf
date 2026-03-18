# Cloud Scheduler Job for triggering Cloud Function every minute
resource "google_cloud_scheduler_job" "autoscaler" {
  name     = "${local.effective_prefix_lower}-autoscale-trigger"
  region   = var.gcp_region
  project  = var.gcp_project_id
  schedule = "* * * * *"
  time_zone = "UTC"

  http_target {
    uri         = google_cloudfunctions2_function.autoscaler.url
    http_method = "POST"

    oidc_token {
      service_account_email = google_service_account.autoscaler.email
    }
  }
}
