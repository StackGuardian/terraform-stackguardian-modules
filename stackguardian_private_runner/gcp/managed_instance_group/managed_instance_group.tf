# Regional Managed Instance Group for HA
resource "google_compute_region_instance_group_manager" "this" {
  name               = local.mig_name
  base_instance_name = "${local.effective_prefix_lower}-runner"
  region             = var.gcp_region
  project            = var.gcp_project_id
  target_size        = var.scaling.desired_capacity

  version {
    instance_template = google_compute_instance_template.this.id
  }

  update_policy {
    type                         = "PROACTIVE"
    minimal_action               = "REPLACE"
    max_surge_fixed              = 1
    max_unavailable_fixed        = 1
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [target_size]
  }
}
