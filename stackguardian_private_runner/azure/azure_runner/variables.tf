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
  type        = string

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
    api_uri  = optional(string, "https://api.app.stackguardian.io")
    org_name = optional(string, "")
  })
  sensitive = true

  validation {
    condition     = can(regex("^sg[uo]_.*", var.stackguardian.api_key))
    error_message = "The api_key must be a valid StackGuardian API key starting with 'sgu_' (user) or 'sgo_' (organization)."
  }

  validation {
    condition = contains([
      "https://api.app.stackguardian.io",
      "https://api.us.stackguardian.io",
      "https://testapi.qa.stackguardian.io"
    ], var.stackguardian.api_uri)
    error_message = "The api_uri must be either 'https://api.app.stackguardian.io' (EU1), 'https://api.us.stackguardian.io' (US1) or 'https://testapi.qa.stackguardian.io' (DASH)."
  }
}

/*-------------------+
 | Resource Naming   |
 +-------------------*/
variable "override_names" {
  description = <<EOT
    Configuration for overriding default resource names.

    - global_prefix: Prefix used for naming all Azure resources created by this module
    - include_org_in_prefix: When true, appends org name to prefix (e.g., SG_RUNNER_demo-org)
    - org_name: Organization name to include in prefix (since this module doesn't resolve it from environment)
  EOT
  type = object({
    global_prefix         = string
    include_org_in_prefix = optional(bool, false)
    org_name              = optional(string, "")
  })
  default = {
    global_prefix = "SG_RUNNER"
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
    - create_network_infrastructure: Whether to create a NAT Gateway (with public IP) and associate it with the subnet for outbound internet access from a private subnet.
      When disabled, ensure the subnet has its own route to the internet (NAT, firewall, ExpressRoute, etc.) for StackGuardian platform connectivity.
    - proxy_url: HTTP proxy URL for private network deployments (e.g., http://proxy.example.com:8080)
    - additional_nsg_ids: Additional NSG IDs to associate with the NIC
  EOT
  type = object({
    create_network                = optional(bool, false)
    vnet_id                       = optional(string, "")
    subnet_id                     = optional(string, "")
    vnet_address_space            = optional(list(string), ["10.0.0.0/16"])
    subnet_address_prefix         = optional(string, "10.0.1.0/24")
    associate_public_ip           = optional(bool, false)
    create_network_infrastructure = optional(bool, false)
    proxy_url                     = optional(string, "")
    additional_nsg_ids            = optional(list(string), [])
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
  description = <<EOT
    Firewall and SSH configuration for the Private Runner instance.

    - admin_username: Linux admin user on the VM
    - ssh_public_key: SSH public key (preferred). Provide your own to avoid
      Terraform generating + storing a private key in state.
    - generate_ssh_key: When true and ssh_public_key is empty, generate an
      RSA keypair and expose the private key as a (sensitive) module output.
      Defaults to false; set explicitly when you accept the state risk.
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
    admin_username   = "azureuser"
    generate_ssh_key = false
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
