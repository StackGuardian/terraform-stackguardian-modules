variable "azure_location" {}
variable "resource_group_name" {}
variable "vm_size" {}
variable "image_publisher" {}
variable "image_offer" {}
variable "image_sku" {}
variable "image_version" {}
variable "image_name_prefix" {}
variable "os_family" {}
variable "ssh_username" {}
variable "update_os_before_install" {}
variable "terraform_version" {}
variable "terraform_versions" {}
variable "opentofu_version" {}
variable "opentofu_versions" {}
variable "user_script" {}
variable "vnet_name" { default = "" }
variable "subnet_name" { default = "" }
variable "vnet_resource_group_name" { default = "" }

packer {
  required_plugins {
    azure = {
      source  = "github.com/hashicorp/azure"
      version = "~> 2"
    }
  }
}

source "azure-arm" "this" {
  # Use Azure CLI authentication (must be logged in)
  use_azure_cli_auth = true

  # Location and VM configuration
  location = var.azure_location
  vm_size  = var.vm_size

  # Source image configuration
  os_type         = "Linux"
  image_publisher = var.image_publisher
  image_offer     = var.image_offer
  image_sku       = var.image_sku
  image_version   = var.image_version

  # Output image configuration
  managed_image_name                = "${var.image_name_prefix}-${var.os_family}-${var.image_sku}-{{timestamp}}"
  managed_image_resource_group_name = var.resource_group_name

  # Network configuration (empty means Packer creates temporary VNet)
  virtual_network_name                = var.vnet_name != "" ? var.vnet_name : null
  virtual_network_subnet_name         = var.subnet_name != "" ? var.subnet_name : null
  virtual_network_resource_group_name = var.vnet_resource_group_name != "" ? var.vnet_resource_group_name : null

  # SSH configuration
  ssh_username = var.ssh_username

  # Azure-specific settings
  azure_tags = {
    purpose = "stackguardian-private-runner"
    os      = var.os_family
  }
}

build {
  sources = ["source.azure-arm.this"]

  # Install dependencies and StackGuardian runner
  provisioner "shell" {
    script = "scripts/setup.sh"
    environment_vars = [
      "OS_FAMILY=${var.os_family}",
      "UPDATE_OS=${var.update_os_before_install}",
      "TERRAFORM_VERSION=${var.terraform_version}",
      "TERRAFORM_VERSIONS=${var.terraform_versions}",
      "OPENTOFU_VERSION=${var.opentofu_version}",
      "OPENTOFU_VERSIONS=${var.opentofu_versions}",
      "USER_SCRIPT=${var.user_script}"
    ]
  }

  # Azure-specific: deprovision the VM (required for image generalization)
  provisioner "shell" {
    execute_command   = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'"
    expect_disconnect = true
    inline = [
      "export HISTSIZE=0",
      "sync",
      "/usr/sbin/waagent -force -deprovision+user || true"
    ]
    inline_shebang = "/bin/sh -x"
  }
}
