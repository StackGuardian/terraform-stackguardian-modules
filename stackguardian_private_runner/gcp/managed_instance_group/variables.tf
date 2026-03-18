/*-------------------+
 | GCP Configuration |
 +-------------------*/
variable "gcp_project_id" {
  description = "The GCP project ID for deploying the Private Runner"
  type        = string
}

variable "gcp_region" {
  description = "The target GCP Region to setup Private Runner"
  type        = string
  default     = "europe-west1"
}

/*--------------------------+
 | GCE Instance Variables   |
 +--------------------------*/
variable "machine_type" {
  description = "The GCE machine type for Private Runner (min 4 vCPU, 16GB RAM recommended)"
  type        = string
  default     = "e2-standard-4"
}

variable "image_self_link" {
  description = <<EOT
    The self link of the GCE image for the Private Runner instance with pre-installed dependencies.
    Required dependencies: docker, cron, jq, sg-runner (main.sh)
    Recommended: Use StackGuardian Template with Packer to build custom image.
  EOT
  type        = string
}

/*-------------------------------------------+
 | StackGuardian Runner Group Configuration  |
 | (from stackguardian_runner_group module)  |
 +-------------------------------------------*/
variable "runner_group_name" {
  description = "The name of the StackGuardian runner group (from stackguardian_runner_group module output)"
  type        = string
}

variable "runner_group_token" {
  description = "The token for runner registration (from stackguardian_runner_group module output)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "storage_backend_role_arn" {
  description = "The ARN of the IAM role for storage backend access (from stackguardian_runner_group module output)"
  type        = string
  default     = ""
}

variable "s3_bucket_name" {
  description = "The name of the S3 bucket used for storage backend (from stackguardian_runner_group module output)"
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

    - global_prefix: Prefix used for naming all GCP resources created by this module
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

/*-----------------------+
 | GCE Network Variables |
 +-----------------------*/
variable "network" {
  description = <<EOT
    Network configuration for the Private Runner instances.

    - network: The VPC network self link or name
    - subnetwork: The subnetwork self link or name for runner instances
    - create_cloud_nat: Whether to create Cloud NAT for private subnet internet access
    - associate_external_ip: Whether to assign external IP to instances
  EOT
  type = object({
    network              = string
    subnetwork           = string
    create_cloud_nat     = optional(bool, false)
    associate_external_ip = optional(bool, false)
  })
}

/*-----------------------+
 | GCE Disk Variables    |
 +-----------------------*/
variable "disk" {
  description = "Boot disk configuration for the Private Runner instances"
  type = object({
    type = optional(string, "pd-ssd")
    size = optional(number, 100)
  })
  default = {}

  validation {
    condition     = contains(["pd-standard", "pd-ssd", "pd-balanced"], var.disk.type)
    error_message = "The disk type must be one of: pd-standard, pd-ssd, pd-balanced."
  }

  validation {
    condition     = var.disk.size >= 10
    error_message = "The disk size must be at least 10 GB."
  }
}

/*------------------------------+
 | GCE Firewall Variables       |
 +------------------------------*/
variable "firewall" {
  description = "Firewall configuration for the Private Runner instances"
  type = object({
    ssh_access_rules = optional(map(string), {})
    additional_ingress_rules = optional(map(object({
      port        = number
      protocol    = string
      cidr_blocks = list(string)
    })), {})
  })
  default = {}
}

/*-----------------------------------+
 | Auto Scaling Configuration       |
 +-----------------------------------*/
variable "scaling" {
  description = "Scaling configuration for the Private Runner MIG capacity limits"
  type = object({
    min_size         = optional(number, 1)
    max_size         = optional(number, 3)
    desired_capacity = optional(number, 1)
  })
  default = {}

  validation {
    condition     = var.scaling.min_size >= 1
    error_message = "min_size must be at least 1."
  }

  validation {
    condition     = var.scaling.max_size >= var.scaling.min_size
    error_message = "max_size must be greater than or equal to min_size."
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
