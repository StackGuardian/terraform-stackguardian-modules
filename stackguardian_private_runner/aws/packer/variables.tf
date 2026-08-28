/*-------------------+
 | General Variables |
 +-------------------*/
variable "aws_region" {
  description = "The target AWS Region to build the Private Runner AMI"
  type        = string
  default     = "eu-central-1"
}

variable "instance_type" {
  description = "The EC2 instance type for the Packer build process (min 2 vCPU, 4GB RAM recommended)"
  type        = string
  default     = "t3.medium"
}

/*----------------------------+
 | AMI Build Network Settings |
 +----------------------------*/
variable "network" {
  description = "Network configuration for the Packer build instance. Provide either public_subnet_id for public builds or private_subnet_id for private network builds."
  type = object({
    vpc_id            = string
    public_subnet_id  = optional(string, "")
    private_subnet_id = optional(string, "")
    proxy_url         = optional(string, "")
  })

  validation {
    condition = (
      (var.network.public_subnet_id != "" && var.network.private_subnet_id == "")
      || (var.network.public_subnet_id == "" && var.network.private_subnet_id != "")
    )
    error_message = "Exactly one of public_subnet_id or private_subnet_id must be provided."
  }
}

/*---------------------------+
 | Operating System Settings |
 +---------------------------*/
variable "os" {
  description = "Operating system configuration for the AMI"
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

  validation {
    condition     = contains(["amazon", "ubuntu", "rhel"], var.os.family)
    error_message = "The os_family must be one of 'amazon', 'ubuntu', or 'rhel'."
  }
}

/*----------------------------------+
 | Packer Configuration Variables   |
 +----------------------------------*/
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
    version           = "1.14.1"
    rebuild_ami_token = ""
    deregistration_protection = {
      enabled       = true
      with_cooldown = false
    }
    delete_snapshots        = true
    cleanup_amis_on_destroy = true
  }
}

/*---------------------------------+
 | Terraform Installation Settings |
 +---------------------------------*/
variable "ami_name_prefix" {
  description = <<EOT
    Prefix of the generated AMI name. The full name is
    {ami_name_prefix}-{os.family}{os.version}-{timestamp}.
    Left at its default, names match what earlier versions of this module
    produced, so existing AMIs keep being discovered.
  EOT
  type        = string
  default     = "SG-RUNNER-ami"

  validation {
    condition     = trimspace(var.ami_name_prefix) != ""
    error_message = "ami_name_prefix must not be empty."
  }
}

variable "terraform" {
  description = "Terraform installation configuration"
  type = object({
    primary_version     = optional(string, "")
    additional_versions = optional(list(string), [])
  })
  default = {
    primary_version     = ""
    additional_versions = []
  }
}

/*-------------------------------+
 | OpenTofu Installation Settings |
 +-------------------------------*/
variable "opentofu" {
  description = "OpenTofu installation configuration"
  type = object({
    primary_version     = optional(string, "")
    additional_versions = optional(list(string), [])
  })
  default = {
    primary_version     = ""
    additional_versions = []
  }
}

/*----------------------------------+
 | StackGuardian Runner Settings    |
 +----------------------------------*/
variable "sg_runner" {
  description = <<EOT
    StackGuardian runner script installation configuration.
    Set pre_release to true to bake the newest pre-release of the sg-runner
    script into the AMI instead of the latest stable release. When no
    pre-release exists, the build falls back to the latest stable release.
    Changing this alone does not rebuild an existing AMI - also change
    packer_config.rebuild_ami_token.
  EOT
  type = object({
    pre_release = optional(bool, false)
  })
  default = {
    pre_release = false
  }
}
