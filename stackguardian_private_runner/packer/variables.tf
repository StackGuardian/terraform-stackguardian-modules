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

/*----------------------------------+
 | AMI Cleanup Configuration       |
 +----------------------------------*/
variable "cleanup_amis_on_destroy" {
  description = "Whether to automatically deregister AMIs and delete snapshots during terraform destroy"
  type        = bool
  default     = true
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
    update_os_before_install = bool
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
  description = "Packer build configuration"
  type = object({
    version = string
  })
  default = {
    version = "1.14.1"
  }
}

/*---------------------------------+
 | Terraform Installation Settings |
 +---------------------------------*/
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
}
