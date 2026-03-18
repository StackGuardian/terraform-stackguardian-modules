# Cloud Function for Autoscaling
resource "google_cloudfunctions2_function" "autoscaler" {
  name     = local.cloud_function_name
  location = var.gcp_region
  project  = var.gcp_project_id

  build_config {
    runtime     = var.cloud_function_config.runtime
    entry_point = "main"

    source {
      storage_source {
        bucket = google_storage_bucket.function_source.name
        object = google_storage_bucket_object.function_zip.name
      }
    }
  }

  service_config {
    max_instance_count    = 1
    available_memory      = var.cloud_function_config.memory
    timeout_seconds       = var.cloud_function_config.timeout
    service_account_email = google_service_account.autoscaler.email

    environment_variables = {
      SCALE_OUT_COOLDOWN_DURATION = tostring(var.scaling.scale_out_cooldown_duration)
      SCALE_IN_COOLDOWN_DURATION  = tostring(var.scaling.scale_in_cooldown_duration)
      SCALE_OUT_THRESHOLD         = tostring(var.scaling.scale_out_threshold)
      SCALE_IN_THRESHOLD          = tostring(var.scaling.scale_in_threshold)
      SCALE_OUT_STEP              = tostring(var.scaling.scale_out_step)
      SCALE_IN_STEP               = tostring(var.scaling.scale_in_step)
      MIN_RUNNERS                 = tostring(var.scaling.min_size)
      SG_BASE_URI                 = local.sg_api_uri
      SG_API_KEY                  = var.stackguardian.api_key
      SG_ORG                      = local.sg_org_name
      SG_RUNNER_GROUP             = var.runner_group_name
      SG_RUNNER_TYPE              = var.runner_type
      GCP_PROJECT_ID              = var.gcp_project_id
      GCP_REGION                  = var.gcp_region
      GCP_MIG_NAME                = var.mig_name
      GCS_BUCKET_NAME             = google_storage_bucket.cooldown_state.name
    }
  }

  depends_on = [
    terraform_data.build_cloud_function,
    google_project_iam_member.autoscaler_compute,
    google_project_iam_member.autoscaler_logging,
    google_project_iam_member.autoscaler_storage
  ]

  lifecycle {
    replace_triggered_by = [terraform_data.build_cloud_function]
  }
}
