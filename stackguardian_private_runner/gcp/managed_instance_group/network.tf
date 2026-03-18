# Optional Cloud NAT infrastructure for private subnet deployments

# Cloud Router for Cloud NAT
resource "google_compute_router" "this" {
  count = local.create_cloud_nat ? 1 : 0

  name    = "${local.effective_prefix_lower}-private-runner-router"
  network = var.network.network
  region  = var.gcp_region
  project = var.gcp_project_id
}

# Cloud NAT for private subnet internet access
resource "google_compute_router_nat" "this" {
  count = local.create_cloud_nat ? 1 : 0

  name                               = "${local.effective_prefix_lower}-private-runner-nat"
  router                             = google_compute_router.this[0].name
  region                             = var.gcp_region
  project                            = var.gcp_project_id
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
