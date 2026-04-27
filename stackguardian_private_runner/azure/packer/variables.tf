/*-------------------+
 | General Variables |
 +-------------------*/
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
  description = "Packer build configuration"
  type = object({
    version                   = optional(string, "1.14.1")
    cleanup_images_on_destroy = optional(bool, true)
  })
  default = {
    version                   = "1.14.1"
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
