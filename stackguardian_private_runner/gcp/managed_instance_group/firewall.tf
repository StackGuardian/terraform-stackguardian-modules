# Firewall rules for Private Runner instances

# Allow SSH (only if SSH access rules are provided)
resource "google_compute_firewall" "allow_ssh" {
  count = length(var.firewall.ssh_access_rules) > 0 ? 1 : 0

  name    = "${local.effective_prefix_lower}-private-runner-allow-ssh"
  network = var.network.network
  project = var.gcp_project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges           = values(var.firewall.ssh_access_rules)
  target_service_accounts = [google_service_account.runner.email]
}

# Allow all egress
resource "google_compute_firewall" "allow_egress" {
  name      = "${local.effective_prefix_lower}-private-runner-allow-egress"
  network   = var.network.network
  project   = var.gcp_project_id
  direction = "EGRESS"

  allow {
    protocol = "all"
  }

  destination_ranges      = ["0.0.0.0/0"]
  target_service_accounts = [google_service_account.runner.email]
}

# Additional ingress rules
resource "google_compute_firewall" "additional_ingress" {
  for_each = var.firewall.additional_ingress_rules

  name    = "${local.effective_prefix_lower}-private-runner-${each.key}"
  network = var.network.network
  project = var.gcp_project_id

  allow {
    protocol = each.value.protocol
    ports    = [tostring(each.value.port)]
  }

  source_ranges           = each.value.cidr_blocks
  target_service_accounts = [google_service_account.runner.email]
}
