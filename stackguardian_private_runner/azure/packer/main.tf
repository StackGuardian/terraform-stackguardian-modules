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
resource "null_resource" "packer_build" {
  provisioner "local-exec" {
    working_dir = path.module
    command     = "sh scripts/build_image.sh"
    environment = {
      PACKER_VERSION           = var.packer_config.version
      AZURE_LOCATION           = var.azure_location
      RESOURCE_GROUP_NAME      = local.resource_group_name
      VM_SIZE                  = var.vm_size
      IMAGE_PUBLISHER          = var.os.publisher
      IMAGE_OFFER              = var.os.offer
      IMAGE_SKU                = var.os.sku
      IMAGE_VERSION            = var.os.version
      IMAGE_NAME_PREFIX        = var.image_name_prefix
      OS_FAMILY                = local.os_family
      SSH_USERNAME             = local.ssh_username
      UPDATE_OS                = var.os.update_os_before_install
      USER_SCRIPT              = var.os.user_script
      TERRAFORM_VERSION        = var.terraform.primary_version
      TERRAFORM_VERSIONS       = join(" ", var.terraform.additional_versions)
      OPENTOFU_VERSION         = var.opentofu.primary_version
      OPENTOFU_VERSIONS        = join(" ", var.opentofu.additional_versions)
      VNET_NAME                = var.network.vnet_name
      SUBNET_NAME              = var.network.subnet_name
      VNET_RESOURCE_GROUP_NAME = var.network.resource_group_name
      PROXY_URL                = var.network.proxy_url
    }
  }

  triggers = {
    timestamp = timestamp()
  }

  depends_on = [azurerm_resource_group.packer]
}

/*-------------------------------------------+
 | Parse the Image ID from Packer Output     |
 +-------------------------------------------*/
data "external" "packer_image_id" {
  working_dir = path.module
  program = [
    "sh",
    "-c",
    "grep 'artifact,0,id' packer_manifest.log | tail -1 | cut -d, -f6 | xargs -I{} echo '{\"image_id\": \"{}\"}'"
  ]

  depends_on = [null_resource.packer_build]
}

/*-------------------------------------------+
 | Conditional Image Cleanup Resource        |
 +-------------------------------------------*/
resource "null_resource" "image_cleanup" {
  count = var.packer_config.cleanup_images_on_destroy ? 1 : 0

  # Store image information as triggers so they're available during destroy
  triggers = {
    image_id            = data.external.packer_image_id.result["image_id"]
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
