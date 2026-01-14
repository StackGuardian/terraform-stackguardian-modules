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

/*-----------------------------------+
 | Scaling Configuration            |
 +-----------------------------------*/
variable "scaling" {
  description = "Auto scaling thresholds and behavior configuration"
  type = object({
    min_size                    = optional(number, 1)
    scale_out_threshold         = optional(number, 3)
    scale_in_threshold          = optional(number, 1)
    scale_out_step              = optional(number, 1)
    scale_in_step               = optional(number, 1)
    scale_out_cooldown_duration = optional(number, 4)
    scale_in_cooldown_duration  = optional(number, 5)
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
