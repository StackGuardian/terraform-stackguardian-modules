/*-----------------------------------+
 | StackGuardian Platform Variables  |
 +-----------------------------------*/
variable "stackguardian" {
  description = "StackGuardian platform configuration (api_key, api_uri, org_name)"
  type = object({
    api_key  = string
    api_uri  = optional(string, "https://api.app.stackguardian.io")
    org_name = optional(string, "")
  })
  sensitive = true
}

/*---------------------+
 | Azure Configuration |
 +---------------------*/
variable "azure_location" {
  description = "Azure region for all resources"
  type        = string
  default     = "westeurope"
}

variable "azure_resource_group_name" {
  description = <<EOT
    Name of the resource group created for the whole deployment (storage backend,
    managed image, and runner VM).
    Leave empty to derive it from the prefix and subscription ID.
  EOT
  type        = string
  default     = ""
}

/*-------------------+
 | Resource Naming   |
 +-------------------*/
variable "override_names" {
  description = "Resource naming configuration"
  type = object({
    global_prefix         = string
    include_org_in_prefix = optional(bool, false)
    runner_group_name     = optional(string, "")
    connector_name        = optional(string, "")
  })
  default = {
    global_prefix = "SG_RUNNER"
  }
}

/*---------------------------+
 | Runner Group Settings     |
 +---------------------------*/
variable "max_runners" {
  description = "Maximum number of runners in the runner group"
  type        = number
  default     = 3
}

variable "azure_storage" {
  description = "Storage account configuration for the runner group storage backend"
  type = object({
    account_tier             = optional(string, "Standard")
    account_replication_type = optional(string, "LRS")
  })
  default = {}
}

variable "create_role_assignments" {
  description = <<EOT
    Whether to create the two role assignments this deployment needs:
    'Storage Blob Data Reader' for the connector service principal, and
    'Storage Blob Data Contributor' for the runner's managed identity.
    Set to false when the identity running OpenTofu lacks
    Microsoft.Authorization/roleAssignments/write - you must then create both
    out of band before runners can use the storage backend.
  EOT
  type        = bool
  default     = true
}

/*---------------------------+
 | Image Build Settings      |
 +---------------------------*/
variable "packer_vm_size" {
  description = "VM size for the Packer build instance"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "packer_network" {
  description = <<EOT
    Network for the Packer build VM.
    Leave vnet_name/subnet_name empty to let Packer create and destroy its own
    temporary networking; set them to build inside an existing VNet.
  EOT
  type = object({
    vnet_name           = optional(string, "")
    subnet_name         = optional(string, "")
    resource_group_name = optional(string, "")
    proxy_url           = optional(string, "")
  })
  default = {}
}

variable "os" {
  description = "Base Marketplace image for the runner image"
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

variable "image_name_prefix" {
  description = "Prefix for the generated managed image name"
  type        = string
  default     = "sg-runner"
}

variable "terraform" {
  description = "Terraform versions to install in the runner image"
  type = object({
    primary_version     = optional(string, "")
    additional_versions = optional(list(string), [])
  })
  default = {}
}

variable "opentofu" {
  description = "OpenTofu versions to install in the runner image"
  type = object({
    primary_version     = optional(string, "")
    additional_versions = optional(list(string), [])
  })
  default = {}
}

/*---------------------------+
 | Runner VM Settings        |
 +---------------------------*/
variable "runner_vm_size" {
  description = "VM size for the Private Runner"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "os_disk" {
  description = "OS disk configuration for the runner VM"
  type = object({
    caching              = optional(string, "ReadWrite")
    storage_account_type = optional(string, "Premium_LRS")
    disk_size_gb         = optional(number, 100)
  })
  default = {}
}

variable "runner_startup_timeout" {
  description = "Seconds to wait for Docker to start before shutting down the VM"
  type        = number
  default     = 300
}

/*-------------------+
 | Network Settings  |
 +-------------------*/
variable "network" {
  description = <<EOT
    VNet and subnet created for the runner VM.

    - service_endpoints: Azure VNet service endpoints enabled on the subnet
      (e.g. ["Microsoft.Storage"]), routing that traffic over the Azure backbone
      instead of the public internet.
  EOT
  type = object({
    vnet_address_space    = optional(list(string), ["10.0.0.0/16"])
    subnet_address_prefix = optional(string, "10.0.1.0/24")
    service_endpoints     = optional(list(string), [])
  })
  default = {}
}

/*-------------------+
 | SSH Access        |
 +-------------------*/
variable "firewall" {
  description = <<EOT
    SSH and NSG configuration for the runner VM.
    Password authentication is always disabled, so one of ssh_public_key or
    generate_ssh_key is required. Prefer supplying your own public key -
    a generated key's private half is stored in state.
  EOT
  type = object({
    admin_username   = optional(string, "azureuser")
    ssh_public_key   = optional(string, "")
    generate_ssh_key = optional(bool, false)
    ssh_access_rules = optional(map(string), {})
    additional_inbound_rules = optional(map(object({
      priority                   = number
      direction                  = optional(string, "Inbound")
      access                     = optional(string, "Allow")
      protocol                   = string
      source_port_range          = optional(string, "*")
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = optional(string, "*")
    })), {})
  })
  default = {
    generate_ssh_key = true
  }
}
