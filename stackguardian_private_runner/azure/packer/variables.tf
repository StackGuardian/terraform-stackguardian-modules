/*-------------------+
 | General Variables |
 +-------------------*/
variable "existing_image_id" {
  description = <<EOT
    Existing managed image to hand back instead of building one.
    Leave it empty and the module runs Packer as usual. Set it to an image you
    already have and the build, the manifest parsing and the destroy-time
    cleanup are all skipped - the module builds nothing and the image_id output
    returns this value unchanged, so a caller can wire the same output either
    way. Every other build input is then ignored.
    Example: /subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Compute/images/{name}
  EOT
  type        = string
  default     = ""

  validation {
    condition     = var.existing_image_id == "" || can(regex("^/subscriptions/", var.existing_image_id))
    error_message = "existing_image_id must be empty (build an image) or a valid Azure resource ID starting with '/subscriptions/'."
  }
}

variable "azure_location" {
  description = "The target Azure region to build the Private Runner image"
  type        = string
  default     = "westeurope"
}

variable "resource_group_name" {
  description = "The name of the resource group where the image will be stored"
  type        = string
}

variable "create_resource_group" {
  description = "Whether to create the resource group (if false, must already exist)"
  type        = bool
  default     = false
}

variable "vm_size" {
  description = "The Azure VM size for the Packer build process (min 2 vCPU, 4GB RAM recommended)"
  type        = string
  default     = "Standard_D2s_v3"
}

/*----------------------------+
 | Image Build Network Settings |
 +----------------------------*/
variable "network" {
  description = <<EOT
    Network configuration for the Packer build instance.
    Leave vnet/subnet empty to let Packer create temporary networking.

    - proxy_url: HTTP proxy URL forwarded to the build VM (e.g. http://proxy.example.com:8080)
  EOT
  type = object({
    vnet_name           = optional(string, "")
    subnet_name         = optional(string, "")
    resource_group_name = optional(string, "")
    proxy_url           = optional(string, "")
  })
  default = {}
}

/*---------------------------+
 | Operating System Settings |
 +---------------------------*/
variable "os" {
  description = "Operating system configuration for the image"
  type = object({
    publisher                = string
    offer                    = string
    sku                      = string
    version                  = optional(string, "latest")
    update_os_before_install = optional(bool, true)
    user_script              = optional(string, "")
  })
  default = {
    publisher                = "Canonical"
    offer                    = "0001-com-ubuntu-server-jammy"
    sku                      = "22_04-lts-gen2"
    version                  = "latest"
    update_os_before_install = true
  }

  validation {
    condition     = contains(["Canonical", "RedHat"], var.os.publisher)
    error_message = "The os.publisher must be one of 'Canonical' or 'RedHat'."
  }
}

/*----------------------------------+
 | Packer Configuration Variables   |
 +----------------------------------*/
variable "packer_config" {
  description = <<EOT
    Packer build configuration.
    The image is built on the first apply and then reused on every following plan.
    To build a new one, change rebuild_image_token to any new value.
  EOT
  type = object({
    version                   = optional(string, "1.14.1")
    rebuild_image_token       = optional(string, "")
    cleanup_images_on_destroy = optional(bool, true)
  })
  default = {
    version                   = "1.14.1"
    rebuild_image_token       = ""
    cleanup_images_on_destroy = true
  }
}

variable "image_name_prefix" {
  description = "Prefix for the generated image name"
  type        = string
  default     = "sg-runner"
}

/*---------------------------------+
 | Terraform Installation Settings |
 +---------------------------------*/
variable "terraform" {
  description = "Terraform installation configuration"
  type = object({
    primary_version     = optional(string, "")
    additional_versions = optional(list(string), [])
  })
  default = {
    primary_version     = ""
    additional_versions = []
  }
}

/*-------------------------------+
 | OpenTofu Installation Settings |
 +-------------------------------*/
variable "opentofu" {
  description = "OpenTofu installation configuration"
  type = object({
    primary_version     = optional(string, "")
    additional_versions = optional(list(string), [])
  })
  default = {
    primary_version     = ""
    additional_versions = []
  }
}

/*---------------------------+
 | Runner Script Settings    |
 +---------------------------*/
variable "sg_runner" {
  description = <<EOT
    StackGuardian runner script installation configuration.
    Set pre_release to true to bake the newest pre-release of the sg-runner
    script into the image instead of the latest stable release. When no
    pre-release exists, the build falls back to the latest stable release.
    Changing this alone does not rebuild an existing image - also change
    packer_config.rebuild_image_token.
  EOT
  type = object({
    pre_release = optional(bool, false)
  })
  default = {
    pre_release = false
  }
}

