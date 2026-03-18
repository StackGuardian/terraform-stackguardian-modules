# GCE Instance Template for Managed Instance Group
resource "google_compute_instance_template" "this" {
  name_prefix  = "${local.effective_prefix_lower}-private-runner-"
  machine_type = var.machine_type
  project      = var.gcp_project_id
  region       = var.gcp_region

  disk {
    source_image = var.image_self_link
    disk_type    = var.disk.type
    disk_size_gb = var.disk.size
    auto_delete  = true
    boot         = true
  }

  network_interface {
    subnetwork = var.network.subnetwork

    dynamic "access_config" {
      for_each = var.network.associate_external_ip ? [1] : []
      content {}
    }
  }

  service_account {
    email  = google_service_account.runner.email
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = templatefile("${path.module}/templates/register_runner.sh.tpl",
    {
      sg_org_name               = local.sg_org_name
      sg_api_uri                = local.sg_api_uri
      sg_runner_group_name      = var.runner_group_name
      sg_runner_group_token     = var.runner_group_token
      sg_runner_startup_timeout = tostring(var.runner_startup_timeout)
      aws_role_arn              = aws_iam_role.gcp_s3_access.arn
    }
  )

  labels = {
    name = "${local.effective_prefix_lower}-private-runner"
  }

  lifecycle {
    create_before_destroy = true
  }
}
