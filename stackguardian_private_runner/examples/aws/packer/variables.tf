/*---------------------+
 | AWS Configuration   |
 +---------------------*/
variable "aws_region" {
  description = "AWS region the AMI is built in. An AMI is regional - it can only launch instances in this region."
  type        = string
  default     = "eu-central-1"
}

/*-------------------+
 | Network Settings  |
 +-------------------*/
variable "network" {
  description = <<EOT
    Existing VPC and subnet the Packer build instance runs in. This example never
    creates networking - point it at a subnet you already have.

    - vpc_id / subnet_id: the existing VPC and the subnet to build in
    - private_subnet: set true when subnet_id is a private subnet. Packer then
      connects over the private IP, so whatever runs OpenTofu needs a route into
      that subnet. Left false, the subnet must be public and reach an internet
      gateway.
    - proxy_url: HTTP proxy forwarded to the build instance

    Either way the subnet needs outbound internet access - the build downloads
    packages, Docker, and the sg-runner release.
  EOT
  type = object({
    vpc_id         = string
    subnet_id      = string
    private_subnet = optional(bool, false)
    proxy_url      = optional(string, "")
  })

  validation {
    condition = alltrue([
      trimspace(var.network.vpc_id) != "",
      trimspace(var.network.subnet_id) != "",
    ])
    error_message = "network.vpc_id and network.subnet_id are both required - this example builds in an existing VPC and subnet."
  }
}

/*---------------------------+
 | Build Instance Settings   |
 +---------------------------*/
variable "instance_type" {
  description = "EC2 instance type for the Packer build instance. It exists only for the length of the build."
  type        = string
  default     = "t3.medium"
}

/*---------------------------+
 | Image Contents            |
 +---------------------------*/
variable "os" {
  description = "Base AMI for the runner image. family must be amazon, ubuntu, or rhel; version is required for ubuntu and rhel."
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
  description = "Prefix of the generated AMI name; the full name is {prefix}-{os.family}{os.version}-{timestamp}"
  type        = string
  default     = "SG-RUNNER-ami"
}

variable "terraform" {
  description = "Terraform versions to install in the image. primary_version lands as /bin/terraform, the rest as /bin/terraform<version>."
  type = object({
    primary_version     = optional(string, "")
    additional_versions = optional(list(string), [])
  })
  default = {}
}

variable "opentofu" {
  description = "OpenTofu versions to install in the image. primary_version lands as /bin/tofu, the rest as /bin/tofu<version>."
  type = object({
    primary_version     = optional(string, "")
    additional_versions = optional(list(string), [])
  })
  default = {}
}

variable "sg_runner" {
  description = <<EOT
    StackGuardian runner script installation configuration.
    Set pre_release to true to bake the newest sg-runner pre-release into the AMI
    instead of the latest stable release; it falls back to stable when no
    pre-release exists.
  EOT
  type = object({
    pre_release = optional(bool, false)
  })
  default = {}
}

/*---------------------------+
 | Build Lifecycle           |
 +---------------------------*/
variable "packer_config" {
  description = <<EOT
    Packer build configuration.
    The AMI is built on the first apply and then reused on every following plan.
    To build a new one, change rebuild_ami_token to any new value.
  EOT
  type = object({
    version           = optional(string, "1.14.1")
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
  default = {}
}
