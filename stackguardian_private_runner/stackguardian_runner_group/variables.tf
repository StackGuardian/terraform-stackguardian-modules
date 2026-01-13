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
    org_name = optional(string, "")
  })
  sensitive = true

  validation {
    condition     = can(regex("^sgu_.*", var.stackguardian.api_key))
    error_message = "The api_key must be a valid StackGuardian API key starting with 'sgu_'."
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
    - runner_group_name: Override the default StackGuardian runner group name. If not provided, uses {global_prefix}-runner-group-{account_id}
    - connector_name: Override the default StackGuardian connector name. If not provided, uses {global_prefix}-private-runner-backend-{account_id}
  EOT
  type = object({
    global_prefix     = string
    runner_group_name = optional(string, "")
    connector_name    = optional(string, "")
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

variable "runner_group_tags" {
  description = "Tags to apply to the runner group"
  type        = list(string)
  default     = ["private-runner"]
}
