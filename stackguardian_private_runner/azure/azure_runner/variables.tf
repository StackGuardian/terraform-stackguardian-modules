/*------------------------+
 | VM Instance Variables  |
 +------------------------*/
variable "vm_size" {
  description = "The Azure VM size for Private Runner (min 4 vCPU, 8GB RAM recommended)"
  type        = string
  default     = "Standard_D4s_v3" # 4 vCPU, 16GB RAM
}

variable "vm_image_id" {
  description = <<EOT
    Required: Custom image ID with pre-installed dependencies.
    The image must have: docker, cron, jq, and sg-runner installed.
    Example: /subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Compute/images/{name}
  EOT
  type = string

  validation {
    condition     = can(regex("^/subscriptions/", var.vm_image_id))
    error_message = "vm_image_id must be a valid Azure resource ID starting with '/subscriptions/'."
  }
}

/*-------------------+
 | General Variables |
 +-------------------*/
variable "azure_location" {
  description = "The target Azure Region to setup Private Runner"
  type        = string
  default     = "westeurope"
}

variable "resource_group_name" {
  description = "The name of the Azure Resource Group for deployment"
  type        = string
}

/*-------------------------------------------+
 | StackGuardian Runner Group Configuration  |
 +-------------------------------------------*/
variable "runner_group_name" {
  description = "The name of the StackGuardian runner group"
  type        = string
}

variable "runner_group_token" {
  description = "The runner group token for registration (from stackguardian_runner_group module output)"
  type        = string
  sensitive   = true
}

variable "storage_backend_identity_id" {
  description = "The resource ID of the User-Assigned Managed Identity for storage backend access (from stackguardian_runner_group module output)"
  type        = string
}

/*-----------------------------------+
 | StackGuardian Platform Variables  |
 +-----------------------------------*/
variable "stackguardian" {
  description = "StackGuardian platform configuration for runner registration"
  type = object({
    api_key  = string
    org_name = optional(string, "")
    api_uri  = optional(string, "")
  })
  sensitive = true
}

/*-------------------+
 | Resource Naming   |
 +-------------------*/
variable "override_names" {
  description = <<EOT
    Configuration for overriding default resource names.

    - global_prefix: Prefix used for naming all Azure resources created by this module
  EOT
  type = object({
    global_prefix = string
  })
  default = {
    global_prefix = "sg-runner"
  }

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-_]*$", var.override_names.global_prefix))
    error_message = "The global_prefix must start with a letter and contain only letters, numbers, hyphens, and underscores."
  }
}

/*-----------------------+
 | Network Variables     |
 +-----------------------*/
variable "network" {
  description = <<EOT
    Network configuration for the Private Runner instance.

    Mode 1 (use existing): Provide existing vnet_id and subnet_id
    Mode 2 (create new): Set create_network = true

    - create_network: Whether to create a new VNet and Subnet
    - vnet_id: Existing VNet resource ID (required when create_network = false)
    - subnet_id: Existing Subnet resource ID (required when create_network = false)
    - vnet_address_space: Address space for new VNet (when create_network = true)
    - subnet_address_prefix: Address prefix for new subnet (when create_network = true)
    - associate_public_ip: Whether to assign public IP to the VM
    - additional_nsg_ids: Additional NSG IDs to associate with the NIC
  EOT
  type = object({
    create_network        = optional(bool, false)
    vnet_id               = optional(string, "")
    subnet_id             = optional(string, "")
    vnet_address_space    = optional(list(string), ["10.0.0.0/16"])
    subnet_address_prefix = optional(string, "10.0.1.0/24")
    associate_public_ip   = optional(bool, false)
    additional_nsg_ids    = optional(list(string), [])
  })

  validation {
    condition = (
      var.network.create_network == true ||
      (var.network.vnet_id != "" && var.network.subnet_id != "")
    )
    error_message = "Either set create_network = true, or provide both vnet_id and subnet_id."
  }
}

/*-----------------------+
 | VM Storage Variables  |
 +-----------------------*/
variable "os_disk" {
  description = "OS disk configuration for the Private Runner instance"
  type = object({
    caching              = optional(string, "ReadWrite")
    storage_account_type = optional(string, "Premium_LRS")
    disk_size_gb         = optional(number, 100)
  })
  default = {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 100
  }

  validation {
    condition     = contains(["None", "ReadOnly", "ReadWrite"], var.os_disk.caching)
    error_message = "OS disk caching must be one of: None, ReadOnly, ReadWrite."
  }

  validation {
    condition     = contains(["Standard_LRS", "StandardSSD_LRS", "Premium_LRS", "Premium_ZRS"], var.os_disk.storage_account_type)
    error_message = "OS disk storage_account_type must be one of: Standard_LRS, StandardSSD_LRS, Premium_LRS, Premium_ZRS."
  }

  validation {
    condition     = var.os_disk.disk_size_gb >= 30
    error_message = "OS disk size must be at least 30 GB."
  }
}

/*------------------------------+
 | SSH Connection Variables     |
 +------------------------------*/
variable "firewall" {
  description = "Firewall and SSH configuration for the Private Runner instance"
  type = object({
    admin_username   = optional(string, "azureuser")
    ssh_public_key   = optional(string, "")
    generate_ssh_key = optional(bool, true)
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
    admin_username   = "azureuser"
    generate_ssh_key = true
  }

  validation {
    condition = (
      var.firewall.ssh_public_key != "" ||
      var.firewall.generate_ssh_key == true
    )
    error_message = "Either provide ssh_public_key or set generate_ssh_key = true."
  }
}

/*-----------------------------------+
 | Runner Startup Variables          |
 +-----------------------------------*/
variable "runner_startup_timeout" {
  description = "Maximum time in seconds to wait for Docker to start before shutting down the instance"
  type        = number
  default     = 300
}
