/*-----------------------------------+
 | Runner Type Configuration        |
 +-----------------------------------*/
variable "runner_type" {
  description = "The type of StackGuardian runner. Determines which queue count metric to use for scaling decisions."
  type        = string
  default     = "external"

  validation {
    condition     = contains(["external", "shared-external"], var.runner_type)
    error_message = "runner_type must be either 'external' (private runners) or 'shared-external' (shared runners)."
  }
}

/*-------------------+
 | General Variables |
 +-------------------*/
variable "aws_region" {
  description = "The target AWS Region to deploy the autoscaler"
  type        = string
  default     = "eu-central-1"
}

/*-----------------------------------+
 | StackGuardian Platform Variables  |
 +-----------------------------------*/
variable "stackguardian" {
  description = "StackGuardian platform configuration for autoscaler"
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

/*-------------------------------------------+
 | Auto Scaling Group Reference              |
 | (from autoscaling_group module output)    |
 +-------------------------------------------*/
variable "asg_name" {
  description = "The name of the Auto Scaling Group to scale (from autoscaling_group module output)"
  type        = string
}

/*-------------------------------------------+
 | Runner Group Reference                    |
 | (from stackguardian_runner_group module)  |
 +-------------------------------------------*/
variable "runner_group_name" {
  description = "The name of the StackGuardian runner group (from stackguardian_runner_group module output)"
  type        = string
}

variable "s3_bucket_name" {
  description = "The name of the S3 bucket used for storage backend (from stackguardian_runner_group module output)"
  type        = string
}

/*-------------------+
 | Resource Naming   |
 +-------------------*/
variable "override_names" {
  description = <<EOT
    Configuration for overriding default resource names.

    - global_prefix: Prefix used for naming all AWS resources created by this module
    - include_org_in_prefix: When true, appends org name to prefix (e.g., SG_RUNNER_demo-org)
  EOT
  type = object({
    global_prefix         = string
    include_org_in_prefix = optional(bool, false)
  })
  default = {
    global_prefix = "SG_RUNNER"
  }
}

/*-------------------+
 | Resource Tagging  |
 +-------------------*/
variable "tags" {
  description = "Additional tags applied to every taggable resource created by this module"
  type        = map(string)
  default     = {}
}

/*-----------------------------------+
 | Scaling Configuration            |
 +-----------------------------------*/
variable "scaling" {
  description = <<EOT
    Auto scaling thresholds and behavior configuration.

    - min_size / max_runners: hard floor and ceiling on ASG instance count.
    - desired_runners: optional initial capacity. If null, the autoscaler picks
      a value between min_size and max_runners on first run.
    - scale_*_threshold: pending-job count that triggers scale in/out.
    - scale_*_step: number of instances to add/remove per decision.
    - scale_*_cooldown_duration: minutes to wait before re-evaluating.
    - schedule_expression: EventBridge Scheduler expression that drives how
      often the Lambda runs (every minute by default).
  EOT
  type = object({
    min_size                    = optional(number, 1)
    max_runners                 = optional(number, 3)
    desired_runners             = optional(number, null)
    scale_out_threshold         = optional(number, 3)
    scale_in_threshold          = optional(number, 1)
    scale_out_step              = optional(number, 1)
    scale_in_step               = optional(number, 1)
    scale_out_cooldown_duration = optional(number, 4)
    scale_in_cooldown_duration  = optional(number, 5)
    schedule_expression         = optional(string, "rate(1 minute)")
  })
  default = {}

  validation {
    condition     = var.scaling.min_size >= 1
    error_message = "min_size must be at least 1."
  }

  validation {
    condition     = var.scaling.scale_out_cooldown_duration >= 4
    error_message = "scale_out_cooldown_duration must be at least 4 minutes."
  }

  validation {
    condition     = var.scaling.max_runners >= var.scaling.min_size
    error_message = "max_runners must be greater than or equal to min_size."
  }

  validation {
    condition = (
      var.scaling.desired_runners == null ||
      (var.scaling.desired_runners >= var.scaling.min_size && var.scaling.desired_runners <= var.scaling.max_runners)
    )
    error_message = "desired_runners must be between min_size and max_runners (inclusive)."
  }

  validation {
    condition     = var.scaling.schedule_expression != ""
    error_message = "schedule_expression must not be empty."
  }
}

/*-----------------------------------+
 | Lambda Configuration             |
 +-----------------------------------*/
variable "lambda_config" {
  description = "Lambda function configuration"
  type = object({
    runtime     = optional(string, "python3.11")
    timeout     = optional(number, 60)
    memory_size = optional(number, 128)
  })
  default = {}
}

/*-----------------------------------+
 | Autoscaler Repository            |
 +-----------------------------------*/
variable "autoscaler_repo" {
  description = "Configuration for the autoscaler Lambda source repository"
  type = object({
    url    = optional(string, "https://github.com/StackGuardian/sg-runner-autoscaler")
    branch = optional(string, "main")
  })
  default = {}
}
