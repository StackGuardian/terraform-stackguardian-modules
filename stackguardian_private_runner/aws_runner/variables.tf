/*------------------------+
 | EC2 Instance Variables |
 +------------------------*/
variable "instance_type" {
  description = "The EC2 instance type for Private Runner (min 4 vCPU, 8GB RAM recommended)"
  type        = string
  default     = "t3.xlarge"
}

variable "ami_id" {
  description = <<EOT
    The AMI ID for the Private Runner instance with pre-installed dependencies.
    Required dependencies: docker, cron, jq, sg-runner (main.sh)
    Recommended: Use StackGuardian Template with Packer to build custom AMI.
  EOT
  type = string

  validation {
    condition     = can(regex("^ami-.*", var.ami_id))
    error_message = "The ami_id must be a valid AMI ID starting with 'ami-'."
  }
}

/*-------------------+
 | General Variables |
 +-------------------*/
variable "aws_region" {
  description = "The target AWS Region to setup Private Runner"
  type        = string
  default     = "eu-central-1"
}

/*-------------------------------------------+
 | StackGuardian Runner Group Configuration  |
 +-------------------------------------------*/
variable "runner_group_name" {
  description = "The name of the StackGuardian runner group. Token and S3 bucket will be fetched automatically."
  type        = string
}

variable "storage_backend_role_arn" {
  description = "The ARN of the IAM role for storage backend access (from stackguardian_runner_group module output)"
  type        = string
}

/*-----------------------------------+
 | StackGuardian Platform Variables  |
 +-----------------------------------*/
variable "stackguardian" {
  description = "StackGuardian platform configuration for runner registration"
  type = object({
    api_key  = string
    org_name = optional(string, "")
    api_uri  = optional(string, "")
  })
  sensitive = true
}

/*-------------------+
 | Resource Naming   |
 +-------------------*/
variable "override_names" {
  description = <<EOT
    Configuration for overriding default resource names.

    - global_prefix: Prefix used for naming all AWS resources created by this module
  EOT
  type = object({
    global_prefix = string
  })
  default = {
    global_prefix = "SG_RUNNER"
  }
}

/*-----------------------+
 | EC2 Network Variables |
 +-----------------------*/
variable "network" {
  description = <<EOT
    Network configuration for the Private Runner instance.

    - vpc_id: Existing VPC ID for deployment
    - subnet_id: Subnet ID for the instance (public or private)
    - associate_public_ip: Whether to assign public IP to instances
    - additional_security_group_ids: (Optional) Additional security group IDs to attach to the instance
  EOT
  type = object({
    vpc_id                        = string
    subnet_id                     = string
    associate_public_ip           = optional(bool, false)
    additional_security_group_ids = optional(list(string), [])
  })
}

/*-----------------------+
 | EC2 Storage Variables |
 +-----------------------*/
variable "volume" {
  description = "EBS volume configuration for the Private Runner instance"
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

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.volume.type)
    error_message = "The volume type must be one of: gp2, gp3, io1, io2."
  }

  validation {
    condition     = var.volume.size >= 8
    error_message = "The volume size must be at least 8 GB."
  }
}

/*------------------------------+
 | EC2 SSH Connection Variables |
 +------------------------------*/
variable "firewall" {
  description = "Firewall and SSH configuration for the Private Runner instance"
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

/*-----------------------------------+
 | Runner Startup Variables          |
 +-----------------------------------*/
variable "runner_startup_timeout" {
  description = "Maximum time in seconds to wait for Docker to start before shutting down the instance"
  type        = number
  default     = 300
}
