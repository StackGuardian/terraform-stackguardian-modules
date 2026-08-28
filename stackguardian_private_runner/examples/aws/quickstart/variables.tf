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
variable "network" {
  description = <<EOT
    Existing VPC and subnet the runner attaches to. This example never creates
    networking - point it at a subnet you already have.

    - vpc_id / subnet_id: the existing VPC, and the subnet that hosts both the
      Packer build instance and the runner. It needs a route to the internet, so
      either a public subnet or a private one behind a NAT gateway.
    - associate_public_ip: give the runner a public IP. Keep it true unless the
      subnet already provides outbound internet access - the runner must reach
      the StackGuardian API.
    - vpc_endpoint_security_group_ids: security groups of interface VPC endpoints
      (STS, SSM, ECR, ...). An inbound HTTPS rule from the runner is added to each.

    NAT gateways, route tables and proxies belong to the subnet you bring:
    configure them there, or use the aws/single_runner module directly.
  EOT
  type = object({
    vpc_id                          = string
    subnet_id                       = string
    associate_public_ip             = optional(bool, true)
    vpc_endpoint_security_group_ids = optional(list(string), [])
  })

  validation {
    condition = alltrue([
      trimspace(var.network.vpc_id) != "",
      trimspace(var.network.subnet_id) != "",
    ])
    error_message = "network.vpc_id and network.subnet_id are both required - this example attaches to an existing VPC and subnet."
  }
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
variable "ami_id" {
  description = <<EOT
    Existing runner AMI to boot instead of building one.
    Leave it empty to run the Packer module and build an AMI; set it to an AMI
    you already built (for example the ami_id output of an earlier apply, or of
    the aws/packer example) and the build is skipped entirely - every other
    Packer input below is then ignored.
    The AMI has to carry docker, cron, jq and sg-runner, and live in aws_region.
  EOT
  type        = string
  default     = ""

  validation {
    condition     = var.ami_id == "" || can(regex("^ami-", var.ami_id))
    error_message = "ami_id must be empty (build an AMI with Packer) or a valid AMI ID starting with 'ami-'."
  }
}

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

variable "ami_name_prefix" {
  description = "Prefix of the generated AMI name"
  type        = string
  default     = "SG-RUNNER-ami"
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
