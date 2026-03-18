variable "source_image_family" {}
variable "source_image_project" {}
variable "project_id" {}
variable "zone" {}
variable "machine_type" {}
variable "ssh_username" {}
variable "network" {}
variable "subnetwork" {}
variable "use_internal_ip" {}
variable "proxy_url" {}
variable "disk_size" {}
variable "disk_type" {}
variable "update_os_before_install" {}
variable "terraform_version" {}
variable "terraform_versions" {}
variable "opentofu_version" {}
variable "opentofu_versions" {}
variable "sg_runner_pre_release" {}
variable "user_script" {}

packer {
  required_plugins {
    googlecompute = {
      source  = "github.com/hashicorp/googlecompute"
      version = "~> 1"
    }
  }
}

source "googlecompute" "this" {
  image_name        = "sg-runner-image-{{timestamp}}"
  image_description = "Custom GCE image built for StackGuardian Private Runner."
  image_family      = "sg-runner"

  project_id        = var.project_id
  zone              = var.zone
  machine_type      = var.machine_type

  source_image_family   = var.source_image_family
  source_image_project_id = [var.source_image_project]

  network           = var.network
  subnetwork        = var.subnetwork
  use_internal_ip   = var.use_internal_ip

  disk_size         = var.disk_size
  disk_type         = var.disk_type

  ssh_username      = var.ssh_username

  metadata = {
    enable-oslogin = "FALSE"
  }
}

build {
  sources = ["source.googlecompute.this"]

  provisioner "shell" {
    script = "scripts/setup.sh"
    environment_vars = [
      "OS_FAMILY=ubuntu",
      "UPDATE_OS=${var.update_os_before_install}",
      "TERRAFORM_VERSION=${var.terraform_version}",
      "TERRAFORM_VERSIONS=${var.terraform_versions}",
      "OPENTOFU_VERSION=${var.opentofu_version}",
      "OPENTOFU_VERSIONS=${var.opentofu_versions}",
      "SG_RUNNER_PRE_RELEASE=${var.sg_runner_pre_release}",
      "USER_SCRIPT=${var.user_script}",
      "PROXY_URL=${var.proxy_url}"
    ]
  }
}
