/*-----------------------------------+
 | StackGuardian Platform Variables  |
 +-----------------------------------*/
variable "stackguardian" {
  description = "StackGuardian platform configuration (api_key, api_uri, org_name)"
  type = object({
    api_key  = string
    api_uri  = optional(string, "https://api.app.stackguardian.io")
    org_name = optional(string, "")
  })
  sensitive = true
}

/*-------------------+
 | AWS Configuration |
 +-------------------*/
variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-central-1"
}

/*-------------------+
 | Network Settings  |
 +-------------------*/
variable "vpc_id" {
  description = "VPC ID where all resources will be deployed"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID for Packer builds and runner deployment"
  type        = string
}

variable "vpc_endpoint_security_group_ids" {
  description = "Security group IDs of VPC interface endpoints (STS, EC2, etc.) that should allow HTTPS from the runner"
  type        = list(string)
  default     = []
}

/*-------------------+
 | Resource Naming   |
 +-------------------*/
variable "override_names" {
  description = "Resource naming configuration"
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
 | Runner Group Settings     |
 +---------------------------*/
variable "max_runners" {
  description = "Maximum number of runners in the runner group"
  type        = number
  default     = 3
}

variable "force_destroy_storage_backend" {
  description = "Force destroy S3 bucket on terraform destroy (deletes all data)"
  type        = bool
  default     = false
}

/*---------------------------+
 | Packer AMI Settings       |
 +---------------------------*/
variable "packer_instance_type" {
  description = "EC2 instance type for the Packer build process"
  type        = string
  default     = "t3.medium"
}

variable "os" {
  description = "Operating system configuration for the runner AMI"
  type = object({
    family                   = string
    version                  = optional(string, "")
    update_os_before_install = optional(bool, false)
    ssh_username             = optional(string, "")
    user_script              = optional(string, "")
  })
  default = {
    family                   = "amazon"
    update_os_before_install = true
  }
}

variable "packer_config" {
  description = <<EOT
    Packer build configuration.
    The AMI is built on the first apply and then reused on every following plan.
    To build a new one, change rebuild_ami_token to any new value.
  EOT
  type = object({
    version           = string
    rebuild_ami_token = optional(string, "")
    deregistration_protection = optional(object({
      enabled       = bool
      with_cooldown = bool
      }), {
      enabled       = true
      with_cooldown = false
    })
    delete_snapshots        = optional(bool, true)
    cleanup_amis_on_destroy = optional(bool, true)
  })
  default = {
    version = "1.14.1"
  }
}

variable "terraform" {
  description = "Terraform versions to install on the runner AMI"
  type = object({
    primary_version     = optional(string, "")
    additional_versions = optional(list(string), [])
  })
  default = {}
}

variable "opentofu" {
  description = "OpenTofu versions to install on the runner AMI"
  type = object({
    primary_version     = optional(string, "")
    additional_versions = optional(list(string), [])
  })
  default = {}
}

variable "sg_runner" {
  description = <<EOT
    StackGuardian runner script installation configuration.
    Set pre_release to true to bake the newest sg-runner pre-release into the
    AMI instead of the latest stable release; it falls back to the latest
    stable release when no pre-release exists.
    Changing this alone does not rebuild an existing AMI - also change
    packer_config.rebuild_ami_token.
  EOT
  type = object({
    pre_release = optional(bool, false)
  })
  default = {}
}

/*---------------------------+
 | Runner Instance Settings  |
 +---------------------------*/
variable "runner_instance_type" {
  description = "EC2 instance type for the Private Runner"
  type        = string
  default     = "t3.xlarge"
}

variable "volume" {
  description = "EBS volume configuration for the runner instance"
  type = object({
    type                  = string
    size                  = number
    delete_on_termination = bool
  })
  default = {
    type                  = "gp3"
    size                  = 100
    delete_on_termination = false
  }
}

variable "firewall" {
  description = "Firewall and SSH configuration for the runner instance"
  type = object({
    ssh_key_name     = optional(string, "")
    ssh_public_key   = optional(string, "")
    ssh_access_rules = optional(map(string), {})
    additional_ingress_rules = optional(map(object({
      port        = number
      protocol    = string
      cidr_blocks = list(string)
    })), {})
  })
  default = {}
}

variable "runner_startup_timeout" {
  description = "Seconds to wait for Docker to start before shutting down the instance"
  type        = number
  default     = 300
}
