/*---------------------------+
 | Storage Backend Options   |
 +---------------------------*/
variable "create_storage_backend" {
  description = <<EOT
    Whether to create a new S3 bucket for storage backend.
    Set to false to use an existing S3 bucket.
  EOT
  type        = bool
  default     = true
}

variable "existing_s3_bucket_name" {
  description = "Name of an existing S3 bucket to use as storage backend (required when create_storage_backend = false)"
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
      "https://api.us.stackguardian.io"
    ], var.stackguardian.api_uri)
    error_message = "The api_uri must be either 'https://api.app.stackguardian.io' (EU1) or 'https://api.us.stackguardian.io' (US1)."
  }
}

/*-------------------+
 | General Variables |
 +-------------------*/
variable "aws_region" {
  description = "The target AWS Region"
  type        = string
  default     = "eu-central-1"
}

variable "override_names" {
  description = <<EOT
    Configuration for overriding default resource names.

    - global_prefix: Prefix used for naming all resources created by this module
    - include_org_in_prefix: When true, appends org name to prefix (e.g., SG_RUNNER_demo-org)
    - runner_group_name: Override the default StackGuardian runner group name. If not provided, uses {effective_prefix}-runner-group-{account_id}
    - connector_name: Override the default StackGuardian connector name. If not provided, uses {effective_prefix}-private-runner-backend-{account_id}
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

