/*-------------------------------------------+
 | Optional Resource Group Creation          |
 +-------------------------------------------*/
resource "azurerm_resource_group" "packer" {
  count = var.create_resource_group ? 1 : 0

  name     = var.resource_group_name
  location = var.azure_location

  tags = {
    purpose = "stackguardian-private-runner-images"
  }
}

/*-------------------------------------------+
 | Build Custom Image Using Packer           |
 +-------------------------------------------*/
#
# Created once per state, so Packer runs on the first apply only. Change
# packer_config.rebuild_image_token to any new value to replace this resource and
# build a fresh image; re-plans with an unchanged token do nothing.
resource "null_resource" "packer_build" {
  provisioner "local-exec" {
    working_dir = path.module
    command     = "sh ../../packer/scripts/build.sh"
    environment = {
      # Drives the shared build script itself
      PACKER_VERSION  = var.packer_config.version
      PACKER_TEMPLATE = "./image.pkr.hcl"

      # Packer reads PKR_VAR_<name> natively, so these reach image.pkr.hcl
      # without the build script having to know the per-cloud variable list.
      PKR_VAR_azure_location           = var.azure_location
      PKR_VAR_resource_group_name      = local.resource_group_name
      PKR_VAR_vm_size                  = var.vm_size
      PKR_VAR_image_publisher          = var.os.publisher
      PKR_VAR_image_offer              = var.os.offer
      PKR_VAR_image_sku                = var.os.sku
      PKR_VAR_image_version            = var.os.version
      PKR_VAR_image_name_prefix        = var.image_name_prefix
      PKR_VAR_os_family                = local.os_family
      PKR_VAR_ssh_username             = local.ssh_username
      PKR_VAR_update_os_before_install = var.os.update_os_before_install
      PKR_VAR_user_script              = var.os.user_script
      PKR_VAR_terraform_version        = var.terraform.primary_version
      PKR_VAR_terraform_versions       = join(" ", var.terraform.additional_versions)
      PKR_VAR_opentofu_version         = var.opentofu.primary_version
      PKR_VAR_opentofu_versions        = join(" ", var.opentofu.additional_versions)
      PKR_VAR_sg_runner_pre_release    = var.sg_runner.pre_release
      PKR_VAR_vnet_name                = var.network.vnet_name
      PKR_VAR_subnet_name              = var.network.subnet_name
      PKR_VAR_vnet_resource_group_name = var.network.resource_group_name
      PKR_VAR_proxy_url                = var.network.proxy_url
    }
  }

  triggers = {
    rebuild_token = var.packer_config.rebuild_image_token
  }

  depends_on = [azurerm_resource_group.packer]
}

/*-------------------------------------------+
 | Parse the Image ID from Packer Output     |
 +-------------------------------------------*/
#
# Only meaningful right after a build. It returns an empty image ID when the log
# is missing (fresh checkout, CI runner) instead of failing the plan, because the
# recorded image ID is read from state via terraform_data.image_id below.
data "external" "packer_image_id" {
  working_dir = path.module
  program = [
    "sh",
    "-c",
    "image_id=$(grep 'artifact,0,id' packer_manifest.log 2>/dev/null | tail -1 | cut -d, -f6); printf '{\"image_id\": \"%s\"}' \"$image_id\""
  ]

  depends_on = [null_resource.packer_build]
}

/*-------------------------------------------+
 | Record the Built Image ID in State        |
 +-------------------------------------------*/
#
# input is only re-read when a build runs (replace_triggered_by); ignore_changes
# keeps the recorded ID untouched by later plans, even if the build log is stale
# or gone.
resource "terraform_data" "image_id" {
  input = data.external.packer_image_id.result["image_id"]

  lifecycle {
    ignore_changes       = [input]
    replace_triggered_by = [null_resource.packer_build]
  }
}

/*-------------------------------------------+
 | Conditional Image Cleanup Resource        |
 +-------------------------------------------*/
#
# Tracks the image this module built, so a destroy never deletes an image it did
# not create. Re-keyed by a rebuild, which deletes the superseded image.
resource "null_resource" "image_cleanup" {
  count = var.packer_config.cleanup_images_on_destroy ? 1 : 0

  # Store image information as triggers so they're available during destroy
  triggers = {
    image_id            = local.image_id
    resource_group_name = local.resource_group_name
    script_path         = "${path.module}/scripts/cleanup_image.sh"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "sh ${self.triggers.script_path}"
    environment = {
      TARGET_IMAGE_ID = self.triggers.image_id
    }
  }

  depends_on = [null_resource.packer_build]
}
