/*---------------------+
 | Azure Configuration |
 +---------------------*/
variable "azure_location" {
  description = "Azure region the image is built in. A managed image is regional - it can only create VMs in this region."
  type        = string
  default     = "westeurope"
}

variable "resource_group_name" {
  description = "Resource group the managed image is stored in. Created by this example unless create_resource_group is false."
  type        = string

  validation {
    condition     = trimspace(var.resource_group_name) != ""
    error_message = "resource_group_name is required."
  }
}

variable "create_resource_group" {
  description = <<EOT
    Whether to create the resource group. Left true, this example owns it and
    `destroy` removes it along with the image. Set false to build into a
    resource group that already exists.
  EOT
  type        = bool
  default     = true
}

/*---------------------------+
 | Build VM Settings         |
 +---------------------------*/
variable "vm_size" {
  description = "VM size for the Packer build machine. It exists only for the length of the build."
  type        = string
  default     = "Standard_D2s_v3"
}

/*-------------------+
 | Network Settings  |
 +-------------------*/
variable "network" {
  description = <<EOT
    Where the build VM runs.

    Left empty, Packer creates and destroys its own temporary VNet for the build -
    the simplest option, and the default.

    Set vnet_name / subnet_name / resource_group_name to build inside a VNet you
    already have. Packer then connects to the build VM over its private IP and
    assigns no public one, so whatever runs OpenTofu needs a route into that
    subnet. Either way the subnet needs outbound internet access.

    - proxy_url: HTTP proxy forwarded to the build VM
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
 | Image Contents            |
 +---------------------------*/
variable "os" {
  description = "Base Marketplace image for the runner image. publisher must be Canonical or RedHat."
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
}

variable "image_name_prefix" {
  description = "Prefix of the generated image name; the full name is {prefix}-{os_family}-{os.sku}-{timestamp}"
  type        = string
  default     = "sg-runner"
}

variable "terraform" {
  description = "Terraform versions to install in the image. primary_version lands as /bin/terraform, the rest as /bin/terraform<version>."
  type = object({
    primary_version     = optional(string, "")
    additional_versions = optional(list(string), [])
  })
  default = {}
}

variable "opentofu" {
  description = "OpenTofu versions to install in the image. primary_version lands as /bin/tofu, the rest as /bin/tofu<version>."
  type = object({
    primary_version     = optional(string, "")
    additional_versions = optional(list(string), [])
  })
  default = {}
}

variable "sg_runner" {
  description = <<EOT
    StackGuardian runner script installation configuration.
    Set pre_release to true to bake the newest sg-runner pre-release into the
    image instead of the latest stable release; it falls back to stable when no
    pre-release exists.
  EOT
  type = object({
    pre_release = optional(bool, false)
  })
  default = {}
}

/*---------------------------+
 | Build Lifecycle           |
 +---------------------------*/
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
  default = {}
}
