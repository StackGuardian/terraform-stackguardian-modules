# Build custom GCE image using Packer
resource "null_resource" "packer_build" {
  provisioner "local-exec" {
    command = "sh ${path.module}/scripts/build_image.sh"
    environment = {
      GCP_PROJECT_ID       = var.gcp_project_id
      GCP_ZONE             = var.gcp_zone
      SOURCE_IMAGE_FAMILY  = var.os.image_family
      SOURCE_IMAGE_PROJECT = var.os.image_project
      MACHINE_TYPE         = var.instance_type
      SSH_USERNAME         = local.ssh_username
      NETWORK              = var.network.network
      SUBNETWORK           = var.network.subnetwork
      USE_INTERNAL_IP      = var.network.use_internal_ip
      PROXY_URL            = var.network.proxy_url
      DISK_SIZE            = var.disk.size
      DISK_TYPE            = var.disk.type
      UPDATE_OS            = var.os.update_os_before_install
      PACKER_VERSION       = var.packer_config.version
      USER_SCRIPT          = var.os.user_script
      TERRAFORM_VERSION    = var.terraform.primary_version
      TERRAFORM_VERSIONS   = join(" ", var.terraform.additional_versions)
      OPENTOFU_VERSION     = var.opentofu.primary_version
      OPENTOFU_VERSIONS    = join(" ", var.opentofu.additional_versions)
    }
  }

  triggers = {
    timestamp = timestamp()
  }
}

# Parse the GCE image name from the Packer output
data "external" "packer_image_name" {
  program = [
    "sh",
    "-c",
    "grep 'artifact,0,id' packer_manifest.log | tail -1 | cut -d, -f6 | xargs -I{} echo '{\"image_name\": \"{}\"}'"
  ]

  depends_on = [null_resource.packer_build]
}
