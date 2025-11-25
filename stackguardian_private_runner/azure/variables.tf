/*-------------------+
 | General Variables |
 +-------------------*/
variable "azure_location" {
  description = "The Azure region where resources will be deployed"
  type        = string
  default     = "westeurope"
}

variable "resource_group_name" {
  description = "The name of the existing Azure Resource Group where resources will be deployed"
  type        = string
}

/*-----------------------------------+
 | StackGuardian Resources Variables |
 +-----------------------------------*/
variable "stackguardian" {
  description = "StackGuardian platform configuration"
  type = object({
    api_key  = string
    org_name = optional(string, "")
  })

  validation {
    condition     = can(regex("^sg[o|u]_.*", var.stackguardian.api_key))
    error_message = "The api_key must be a valid StackGuardian API key starting with 'sgu_'."
  }
}

variable "override_names" {
  description = <<EOT
    Configuration for overriding default resource names.

    - global_prefix: Prefix used for naming all Azure resources created by this module
    - runner_group_name: Override the default StackGuardian runner group name
  EOT
  type = object({
    global_prefix     = string
    runner_group_name = optional(string, "")
  })
  default = {
    global_prefix = "sg-runner"
  }

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.override_names.global_prefix))
    error_message = "The global_prefix must start with a lowercase letter and contain only lowercase letters, numbers, and hyphens."
  }
}

/*-------------------------------+
 | VM Scale Set Variables        |
 +-------------------------------*/
variable "vmss" {
  description = <<EOT
    Configuration for the existing VM Scale Set to be managed by the autoscaler.

    - name: Name of the existing VM Scale Set
    - resource_group_name: Resource group containing the VM Scale Set (defaults to var.resource_group_name if not specified)
  EOT
  type = object({
    name                = string
    resource_group_name = optional(string, "")
  })
}

/*-----------------------------------+
 | Azure Function Autoscaling Vars  |
 +-----------------------------------*/
variable "scaling" {
  description = "Auto scaling configuration for the Private Runner"
  type = object({
    scale_out_cooldown_duration = optional(number, 4)
    scale_in_cooldown_duration  = optional(number, 5)
    scale_out_threshold         = optional(number, 3)
    scale_in_threshold          = optional(number, 1)
    scale_in_step               = optional(number, 1)
    scale_out_step              = optional(number, 1)
    min_runners                 = optional(number, 1)
  })
  default = {
    scale_out_cooldown_duration = 4
    scale_in_cooldown_duration  = 5
    scale_out_threshold         = 3
    scale_in_threshold          = 1
    scale_in_step               = 1
    scale_out_step              = 1
    min_runners                 = 1
  }

  validation {
    condition     = var.scaling.scale_out_cooldown_duration >= 4
    error_message = "The scale_out_cooldown_duration must be at least 4 minutes."
  }

  validation {
    condition     = var.scaling.scale_in_threshold >= 1
    error_message = "The scale_in_threshold must be at least 1."
  }

  validation {
    condition     = var.scaling.scale_in_step >= 1
    error_message = "The scale_in_step must be at least 1."
  }

  validation {
    condition     = var.scaling.scale_out_step >= 1
    error_message = "The scale_out_step must be at least 1."
  }

  validation {
    condition     = var.scaling.min_runners >= 1
    error_message = "The min_runners must be at least 1."
  }

  validation {
    condition     = var.scaling.min_runners <= var.scaling.scale_out_threshold
    error_message = "The min_runners must be less than or equal to scale_out_threshold."
  }

  validation {
    condition     = var.scaling.scale_in_threshold <= var.scaling.scale_out_threshold
    error_message = "The scale_in_threshold must be less than or equal to scale_out_threshold."
  }
}

/*---------------------------+
 | Storage Backend Variables |
 +---------------------------*/
variable "storage" {
  description = <<EOT
    Storage configuration for the autoscaler state.

    - account_tier: Performance tier of the storage account (Standard or Premium)
    - account_replication_type: Replication strategy (LRS, GRS, RAGRS, ZRS)
  EOT
  type = object({
    account_tier             = optional(string, "Standard")
    account_replication_type = optional(string, "LRS")
  })
  default = {
    account_tier             = "Standard"
    account_replication_type = "LRS"
  }

  validation {
    condition     = contains(["Standard", "Premium"], var.storage.account_tier)
    error_message = "The account_tier must be either 'Standard' or 'Premium'."
  }

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS"], var.storage.account_replication_type)
    error_message = "The account_replication_type must be one of: LRS, GRS, RAGRS, ZRS."
  }
}
