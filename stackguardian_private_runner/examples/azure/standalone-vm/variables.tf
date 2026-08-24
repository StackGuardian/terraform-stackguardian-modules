/*-----------------------------------+
 | StackGuardian Platform Variables  |
 +-----------------------------------*/
variable "stackguardian" {
  description = "StackGuardian platform configuration"
  type = object({
    api_key  = string
    api_uri  = optional(string, "https://api.app.stackguardian.io")
    org_name = optional(string, "")
  })
  sensitive = true

  validation {
    condition     = can(regex("^sg[uo]_.*", var.stackguardian.api_key))
    error_message = "The api_key must be a valid StackGuardian API key starting with 'sgu_' or 'sgo_'."
  }
}

/*-------------------------------------------+
 | StackGuardian Runner Group Configuration  |
 +-------------------------------------------*/
variable "runner_storage_resource_group_name" {
  description = "The Azure Resource Group where the runner_group storage account is created"
  type        = string
}

variable "azure_storage" {
  description = "Azure Storage Account configuration for the runner group storage backend"
  type = object({
    account_tier             = optional(string, "Standard")
    account_replication_type = optional(string, "LRS")
  })
  default = {}
}

variable "max_runners" {
  description = "Maximum number of runners for the runner group"
  type        = number
  default     = 3
}

/*-------------------+
 | Azure Variables   |
 +-------------------*/
variable "azure_location" {
  description = "The Azure region where resources will be deployed"
  type        = string
  default     = "westeurope"
}

variable "compute_resource_group_name" {
  description = "The Azure Resource Group where the runner VM and network are created (must already exist)"
  type        = string
}

/*--------------------------+
 | VM Image Variables       |
 +--------------------------*/
variable "rhel_image" {
  description = <<EOT
    Azure Marketplace RHEL image to boot. Replicates the production host OS.
    Verify the exact SKU is offered in your region before apply, e.g.:
      az vm image list --location <region> --publisher RedHat --offer RHEL --all -o table
  EOT
  type = object({
    publisher = optional(string, "RedHat")
    offer     = optional(string, "RHEL")
    sku       = optional(string, "9_8")
    version   = optional(string, "latest")
  })
  default = {}
}

variable "docker_version" {
  description = "Docker engine version to pin (matches the production host, e.g. 29.5.2)"
  type        = string
  default     = "29.5.2"
}

variable "sg_runner_version" {
  description = "sg-runner release tag to pin (the 'Installationsscript' version, e.g. v2.2.1)"
  type        = string
  default     = "v2.2.1"
}

/*--------------------------+
 | VM Variables             |
 +--------------------------*/
variable "vm_size" {
  description = "The Azure VM size for the runner VM"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "admin_username" {
  description = "Admin username for the runner VM"
  type        = string
  default     = "azureuser"
}

variable "admin_ssh_public_key" {
  description = "SSH public key for admin access to the runner VM"
  type        = string
}

variable "vm_os_disk" {
  description = "OS disk configuration for the runner VM"
  type = object({
    caching              = optional(string, "ReadWrite")
    storage_account_type = optional(string, "Premium_LRS")
    disk_size_gb         = optional(number, 50)
  })
  default = {}
}

/*--------------------------+
 | Network Variables        |
 +--------------------------*/
variable "network" {
  description = <<EOT
    Network configuration for the runner VM.

    - vnet_address_space: Address space for the new VNet
    - subnet_address_prefix: Address prefix for the runner subnet
  EOT
  type = object({
    vnet_address_space    = optional(list(string), ["10.0.0.0/16"])
    subnet_address_prefix = optional(string, "10.0.1.0/24")
  })
  default = {}
}

variable "ssh_source_address_prefix" {
  description = "Source IP/CIDR allowed to SSH into the runner VM on port 22 (e.g. 203.0.113.7/32)"
  type        = string
}

/*--------------------------+
 | Resource Naming          |
 +--------------------------*/
variable "prefix" {
  description = "Prefix for naming all resources"
  type        = string
  default     = "SG_RUNNER"
}

/*-----------------------------------+
 | Runner Startup Variables          |
 +-----------------------------------*/
variable "runner_startup_timeout" {
  description = "Maximum time in seconds to wait for Docker to start before failing the install"
  type        = number
  default     = 300
}
