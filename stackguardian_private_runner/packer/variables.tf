/*-------------------+
 | General Variables |
 +-------------------*/
variable "aws_region" {
  description = "The target AWS Region to build the Private Runner AMI"
  type        = string
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
  description = "Network configuration for the Packer build instance"
  type = object({
    vpc_id           = string
    public_subnet_id = string
  })
  default = {
    vpc_id           = ""
    public_subnet_id = ""
  }
}

/*---------------------------+
 | Operating System Settings |
 +---------------------------*/
variable "os" {
  description = "Operating system configuration for the AMI"
  type = object({
    family                   = string
    version                  = string
    update_os_before_install = bool
    ssh_username             = string
    user_script              = string
  })
  default = {
    family                   = "amazon"
    version                  = ""
    update_os_before_install = true
    ssh_username             = ""
    user_script              = ""
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
    primary_version     = string
    additional_versions = list(string)
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
    primary_version     = string
    additional_versions = list(string)
  })
  default = {
    primary_version     = ""
    additional_versions = []
  }
}
