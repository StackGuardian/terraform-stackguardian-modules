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

variable "override_names" {
  description = <<EOT
    Configuration for overriding default resource names.

    - global_prefix: Prefix used for naming all Azure resources created by this module
    - include_org_in_prefix: When true, appends org name to prefix (e.g., SG_RUNNER_demo-org)
    - runner_group_name: Override the default StackGuardian runner group name
  EOT
  type = object({
    global_prefix         = string
    include_org_in_prefix = optional(bool, false)
    runner_group_name     = optional(string, "")
  })
  default = {
    global_prefix = "SG_RUNNER"
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
  description = <<EOT
    Auto scaling configuration for the Private Runner.

    - min_runners / max_runners: hard floor and ceiling on VMSS instance count.
    - desired_runners: optional initial capacity. If null, the autoscaler picks
      a value between min_runners and max_runners on first run.
    - scale_*_threshold: pending-job count that triggers scale in/out.
    - scale_*_step: number of instances to add/remove per decision.
    - scale_*_cooldown_duration: minutes to wait before re-evaluating.
    - schedule_cron: NCRONTAB expression that drives the Function App timer
      trigger (every minute by default). Empty string keeps whatever cadence
      is baked into the deployed function code.
  EOT
  type = object({
    scale_out_cooldown_duration = optional(number, 4)
    scale_in_cooldown_duration  = optional(number, 5)
    scale_out_threshold         = optional(number, 3)
    scale_in_threshold          = optional(number, 1)
    scale_in_step               = optional(number, 1)
    scale_out_step              = optional(number, 1)
    min_runners                 = optional(number, 1)
    max_runners                 = optional(number, 3)
    desired_runners             = optional(number, null)
    schedule_cron               = optional(string, "0 */1 * * * *")
  })
  default = {
    scale_out_cooldown_duration = 4
    scale_in_cooldown_duration  = 5
    scale_out_threshold         = 3
    scale_in_threshold          = 1
    scale_in_step               = 1
    scale_out_step              = 1
    min_runners                 = 1
    max_runners                 = 3
    schedule_cron               = "0 */1 * * * *"
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

  validation {
    condition     = var.scaling.max_runners >= var.scaling.min_runners
    error_message = "The max_runners must be greater than or equal to min_runners."
  }

  validation {
    condition = (
      var.scaling.desired_runners == null ||
      (var.scaling.desired_runners >= var.scaling.min_runners && var.scaling.desired_runners <= var.scaling.max_runners)
    )
    error_message = "The desired_runners must be between min_runners and max_runners (inclusive)."
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
    - account_url: Optional explicit storage account URL (for private endpoints)
    - use_rbac: Use managed identity (RBAC) instead of connection strings for storage authentication
  EOT
  type = object({
    account_tier             = optional(string, "Standard")
    account_replication_type = optional(string, "LRS")
    account_url              = optional(string, "")
    use_rbac                 = optional(bool, false)
  })
  default = {
    account_tier             = "Standard"
    account_replication_type = "LRS"
    account_url              = ""
    use_rbac                 = false
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

/*-----------------------------------+
 | Monitoring Configuration          |
 +-----------------------------------*/
variable "application_insights_retention_in_days" {
  description = <<EOT
    Retention period (in days) for Application Insights telemetry.

    Application Insights only accepts 30, 60, 90, 120, 180, 270, 365, 550 or
    730, so 30 is the closest match to the 14-day CloudWatch retention used by
    the AWS autoscaler.
  EOT
  type        = number
  default     = 30

  validation {
    condition     = contains([30, 60, 90, 120, 180, 270, 365, 550, 730], var.application_insights_retention_in_days)
    error_message = "The application_insights_retention_in_days must be one of: 30, 60, 90, 120, 180, 270, 365, 550, 730."
  }
}

/*-----------------------------------+
 | Autoscaler Repository            |
 +-----------------------------------*/
variable "autoscaler_repo" {
  description = "Configuration for the autoscaler Function App source repository"
  type = object({
    url    = optional(string, "https://github.com/StackGuardian/sg-runner-autoscaler")
    branch = optional(string, "main")
  })
  default = {}
}
