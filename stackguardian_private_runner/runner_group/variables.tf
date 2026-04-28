/*---------------------------+
 | Cloud Provider Toggle     |
 +---------------------------*/
variable "cloud_provider" {
  description = "The cloud provider for the storage backend. Determines which resources are created (AWS S3 or Azure Blob Storage)."
  type        = string
  default     = "aws"

  validation {
    condition     = contains(["aws", "azure"], var.cloud_provider)
    error_message = "The cloud_provider must be either 'aws' or 'azure'."
  }
}

/*---------------------------+
 | Storage Backend Options   |
 +---------------------------*/
variable "create_storage_backend" {
  description = <<EOT
    Whether to create a new storage backend (S3 bucket for AWS, Storage Account for Azure).
    Set to false to use an existing storage backend.
  EOT
  type        = bool
  default     = true
}

variable "existing_s3_bucket_name" {
  description = "Name of an existing S3 bucket to use as storage backend (required when cloud_provider = 'aws' and create_storage_backend = false)"
  type        = string
  default     = ""
}

variable "force_destroy_storage_backend" {
  description = <<EOT
    Whether to force destroy the storage backend (S3 bucket) when the module is destroyed.
    This will delete all data in the bucket, so use with caution.
    Default is false, meaning the bucket will not be deleted if it contains objects.
  EOT
  type        = bool
  default     = false
}

/*---------------------------+
 | Azure Storage Variables   |
 +---------------------------*/
variable "azure_location" {
  description = "The Azure region where resources will be deployed (required when cloud_provider = 'azure')"
  type        = string
  default     = "westeurope"
}

variable "create_azure_resource_group" {
  description = <<EOT
    Whether to create a new Azure Resource Group to host the storage account (and to be reused by downstream azure/* modules via the azure_resource_group_name output).
    Set to false to deploy the storage account into an existing resource group passed via azure_resource_group_name.
  EOT
  type        = bool
  default     = true
}

variable "azure_resource_group_name" {
  description = <<EOT
    Name of the Azure Resource Group used by the module.

    - When create_azure_resource_group = true (default), this is an optional override for the new resource group's name. If left empty, the name is derived from the module's effective_prefix and account identifier.
    - When create_azure_resource_group = false, this must be the name of an existing resource group to deploy the storage account into.
  EOT
  type        = string
  default     = ""
}

variable "existing_azure_storage_account_name" {
  description = "Name of an existing Azure Storage Account to use as storage backend (required when cloud_provider = 'azure' and create_storage_backend = false)"
  type        = string
  default     = ""
}

variable "existing_azure_storage_account_access_key" {
  description = "Access key for the existing Azure Storage Account (required when cloud_provider = 'azure' and create_storage_backend = false)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "azure_storage" {
  description = <<EOT
    Azure Storage Account configuration (used when cloud_provider = 'azure' and create_storage_backend = true).

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
    condition     = contains(["Standard", "Premium"], var.azure_storage.account_tier)
    error_message = "The account_tier must be either 'Standard' or 'Premium'."
  }

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS"], var.azure_storage.account_replication_type)
    error_message = "The account_replication_type must be one of: LRS, GRS, RAGRS, ZRS."
  }
}

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
 | General Variables |
 +-------------------*/
variable "aws_region" {
  description = "The target AWS Region (used when cloud_provider = 'aws')"
  type        = string
  default     = "eu-central-1"
}

variable "override_names" {
  description = <<EOT
    Configuration for overriding default resource names.

    - global_prefix: Prefix used for naming all resources created by this module
    - include_org_in_prefix: When true, appends org name to prefix (e.g., SG_RUNNER_demo-org)
    - runner_group_name: Override the default StackGuardian runner group name. If not provided, uses {effective_prefix}-runner-group-{account_id}
    - connector_name: Override the default StackGuardian connector name (AWS only). If not provided, uses {effective_prefix}-private-runner-backend-{account_id}
  EOT
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
 | Runner Group Configuration |
 +---------------------------*/
variable "max_runners" {
  description = "Maximum number of runners allowed in the runner group"
  type        = number
  default     = 3

  validation {
    condition     = var.max_runners >= 1
    error_message = "max_runners must be at least 1."
  }
}
