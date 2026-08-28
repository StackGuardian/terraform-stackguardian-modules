/*--------------------------------+
 | VM Scale Set Instance Variables |
 +--------------------------------*/
variable "vm_size" {
  description = "The Azure VM size for each scale-set instance (min 4 vCPU, 8GB RAM recommended)"
  type        = string
  default     = "Standard_D4s_v3"
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
  description = "The target Azure Region to setup Private Runner Scale Set"
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
    - include_org_in_prefix: When true, appends the org name to the prefix (e.g., SG_RUNNER_demo-org).
      The org name always comes from stackguardian.org_name, falling back to the SG_ORG_ID
      environment variable - there is no separate override here.
  EOT
  type = object({
    global_prefix         = string
    include_org_in_prefix = optional(bool, false)
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
    Network configuration for the Private Runner Scale Set.

    Mode 1 (use existing): Provide existing vnet_id and subnet_id.
    Mode 2 (create new): Set create_network = true.

    - create_network: Whether to create a new VNet and Subnet
    - vnet_id: Existing VNet resource ID (required when create_network = false)
    - subnet_id: Existing Subnet resource ID (required when create_network = false)
    - vnet_address_space: Address space for new VNet (when create_network = true)
    - subnet_address_prefix: Address prefix for new subnet (when create_network = true)
    - create_network_infrastructure: Create a NAT Gateway (with public IP) and
      associate it with the (created) subnet for outbound internet access.
      Only takes effect together with create_network = true - the module never
      attaches a NAT Gateway to a subnet it does not own.
    - proxy_url: HTTP proxy URL for private network deployments
    - additional_nsg_ids: Additional NSG IDs to associate with each instance
    - service_endpoints: (Optional) VNet service endpoints to enable on the subnet this
      module creates, so runners reach Azure PaaS over the Azure backbone instead of the
      public internet. Typical values: Microsoft.Storage, Microsoft.KeyVault,
      Microsoft.ContainerRegistry. Ignored when bringing an existing subnet - add the
      endpoints on that subnet yourself.
  EOT
  type = object({
    create_network                = optional(bool, false)
    vnet_id                       = optional(string, "")
    subnet_id                     = optional(string, "")
    vnet_address_space            = optional(list(string), ["10.0.0.0/16"])
    subnet_address_prefix         = optional(string, "10.0.1.0/24")
    create_network_infrastructure = optional(bool, false)
    proxy_url                     = optional(string, "")
    additional_nsg_ids            = optional(list(string), [])
    service_endpoints             = optional(list(string), [])
  })

  validation {
    condition = (
      var.network.create_network == true ||
      (var.network.vnet_id != "" && var.network.subnet_id != "")
    )
    error_message = "Either set create_network = true, or provide both vnet_id and subnet_id."
  }

  validation {
    condition = alltrue([
      for endpoint in var.network.service_endpoints : can(regex("^Microsoft\\.[A-Za-z]+(\\.[A-Za-z]+)?$", endpoint))
    ])
    error_message = "Each service_endpoints entry must be an Azure service endpoint name such as 'Microsoft.Storage' or 'Microsoft.KeyVault'."
  }
}

/*-----------------------+
 | VM Storage Variables  |
 +-----------------------*/
variable "os_disk" {
  description = "OS disk configuration for each scale-set instance"
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
    Firewall and SSH configuration for scale-set instances.

    - admin_username: Linux admin user on each instance
    - ssh_public_key: SSH public key (preferred). Provide your own to avoid
      Terraform generating + storing a private key in state.
    - generate_ssh_key: When true and ssh_public_key is empty, generate an
      RSA keypair and expose the private key as a (sensitive) module output.
      Defaults to false.
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

/*--------------------------+
 | Auto Scaling Variables   |
 +--------------------------*/
variable "scaling" {
  description = <<EOT
    Capacity controls for the VM Scale Set.

    - min_size: floor on instance count (the autoscaler will not scale below this)
    - max_size: ceiling on instance count
    - desired_capacity: initial instance count. Marked ignore_changes after
      apply so the autoscaler can drive scale in/out without Terraform fighting it.
  EOT
  type = object({
    min_size         = optional(number, 1)
    max_size         = optional(number, 3)
    desired_capacity = optional(number, 1)
  })
  default = {
    min_size         = 1
    max_size         = 3
    desired_capacity = 1
  }

  validation {
    condition     = var.scaling.min_size >= 1
    error_message = "min_size must be at least 1."
  }

  validation {
    condition     = var.scaling.max_size >= var.scaling.min_size
    error_message = "max_size must be greater than or equal to min_size."
  }

  validation {
    condition = (
      var.scaling.desired_capacity >= var.scaling.min_size &&
      var.scaling.desired_capacity <= var.scaling.max_size
    )
    error_message = "desired_capacity must be between min_size and max_size (inclusive)."
  }
}

/*--------------------------+
 | Upgrade Policy Variables |
 +--------------------------*/
variable "upgrade_policy" {
  description = <<EOT
    How the scale set rolls out model changes (a new vm_image_id, vm_size, custom_data, ...).

    Defaults to "Manual", which is the historical behaviour: existing instances keep running
    the old model until they are replaced by the autoscaler or by an operator. Opt in to
    "Rolling" (or "Automatic") to have Azure replace instances in batches automatically.

    - mode: Manual (default) | Rolling | Automatic. Azure cannot change the upgrade mode of
      an existing scale set, so switching this replaces the VMSS (all runners are recreated).
    - health_probe_id: Load Balancer probe used to judge instance health. Azure requires a
      health signal for Rolling/Automatic upgrades and for automatic instance repair - supply
      either this or application_health_extension.
    - application_health_extension: Installs the in-guest Application Health extension, which
      probes the instance locally (no Load Balancer needed). protocol tcp|http|https, port,
      and request_path (http/https only).
    - max_batch_instance_percent: Max percent of instances upgraded in a single batch.
    - max_unhealthy_instance_percent: Max percent of instances allowed to be unhealthy during
      the upgrade. Must be >= max_batch_instance_percent.
    - max_unhealthy_upgraded_instance_percent: Max percent of already-upgraded instances
      allowed to be unhealthy before the upgrade aborts.
    - pause_time_between_batches: ISO 8601 duration to wait between batches (e.g. PT5M).
    - automatic_instance_repair: Let Azure replace instances that report unhealthy. Also
      requires a health signal.
    - automatic_instance_repair_grace_period: ISO 8601 grace period after a state change
      before repairs kick in (30-90 minutes).
  EOT
  type = object({
    mode            = optional(string, "Manual")
    health_probe_id = optional(string, "")
    application_health_extension = optional(object({
      protocol     = optional(string, "tcp")
      port         = optional(number, 22)
      request_path = optional(string, "")
    }), null)
    max_batch_instance_percent              = optional(number, 20)
    max_unhealthy_instance_percent          = optional(number, 20)
    max_unhealthy_upgraded_instance_percent = optional(number, 20)
    pause_time_between_batches              = optional(string, "PT5M")
    automatic_instance_repair               = optional(bool, false)
    automatic_instance_repair_grace_period  = optional(string, "PT30M")
  })
  default = {
    mode = "Manual"
  }

  validation {
    condition     = contains(["Manual", "Rolling", "Automatic"], var.upgrade_policy.mode)
    error_message = "The upgrade_policy.mode must be one of: Manual, Rolling, Automatic."
  }

  validation {
    condition = (
      var.upgrade_policy.mode == "Manual" ||
      var.upgrade_policy.health_probe_id != "" ||
      var.upgrade_policy.application_health_extension != null
    )
    error_message = "Rolling and Automatic upgrades need a health signal: set upgrade_policy.health_probe_id or upgrade_policy.application_health_extension."
  }

  validation {
    condition = (
      !var.upgrade_policy.automatic_instance_repair ||
      var.upgrade_policy.health_probe_id != "" ||
      var.upgrade_policy.application_health_extension != null
    )
    error_message = "The upgrade_policy.automatic_instance_repair needs a health signal: set upgrade_policy.health_probe_id or upgrade_policy.application_health_extension."
  }

  validation {
    condition = (
      var.upgrade_policy.application_health_extension == null ||
      contains(["tcp", "http", "https"], try(var.upgrade_policy.application_health_extension.protocol, ""))
    )
    error_message = "The upgrade_policy.application_health_extension.protocol must be one of: tcp, http, https."
  }

  validation {
    condition = (
      var.upgrade_policy.application_health_extension == null ||
      try(var.upgrade_policy.application_health_extension.protocol, "") == "tcp" ||
      try(var.upgrade_policy.application_health_extension.request_path, "") != ""
    )
    error_message = "The upgrade_policy.application_health_extension.request_path is required when protocol is http or https."
  }

  validation {
    condition = (
      var.upgrade_policy.max_batch_instance_percent >= 5 &&
      var.upgrade_policy.max_batch_instance_percent <= 100 &&
      var.upgrade_policy.max_unhealthy_instance_percent >= 5 &&
      var.upgrade_policy.max_unhealthy_instance_percent <= 100 &&
      var.upgrade_policy.max_unhealthy_upgraded_instance_percent >= 0 &&
      var.upgrade_policy.max_unhealthy_upgraded_instance_percent <= 100
    )
    error_message = "The max_batch_instance_percent and max_unhealthy_instance_percent must be between 5 and 100, max_unhealthy_upgraded_instance_percent between 0 and 100."
  }

  validation {
    condition     = var.upgrade_policy.max_unhealthy_instance_percent >= var.upgrade_policy.max_batch_instance_percent
    error_message = "The max_unhealthy_instance_percent must be greater than or equal to max_batch_instance_percent."
  }

  validation {
    condition     = can(regex("^P(T?[0-9]+[DHMS])+$", var.upgrade_policy.pause_time_between_batches))
    error_message = "The pause_time_between_batches must be an ISO 8601 duration (e.g. PT0S, PT5M)."
  }

  validation {
    condition     = can(regex("^P(T?[0-9]+[DHMS])+$", var.upgrade_policy.automatic_instance_repair_grace_period))
    error_message = "The automatic_instance_repair_grace_period must be an ISO 8601 duration (e.g. PT30M)."
  }
}

/*-----------------------------------+
 | Runner Startup Variables          |
 +-----------------------------------*/
variable "runner_startup_timeout" {
  description = "Maximum time in seconds to wait for Docker to start before shutting down each instance"
  type        = number
  default     = 300
}
