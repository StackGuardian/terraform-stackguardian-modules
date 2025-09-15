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
  type        = string

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

/*---------------------------+
 | Backend Storage Variables |
 +---------------------------*/
variable "force_destroy_storage_backend" {
  description = <<EOT
    Whether to force destroy the storage backend (S3 bucket) when the module is destroyed.
    This will delete all data in the bucket, so use with caution.
    Default is false, meaning the bucket will not be deleted if it contains objects.
  EOT
  type        = bool
  default     = false
}

/*-----------------------------------+
 | StackGuardian Resources Variables |
 +-----------------------------------*/
variable "stackguardian" {
  description = "StackGuardian platform configuration"
  type = object({
    api_key  = string
    org_name = optional(string, "")
  })

  validation {
    condition     = can(regex("^sgu_.*", var.stackguardian.api_key))
    error_message = "The api_key must be a valid StackGuardian API key starting with 'sgu_'."
  }
}

variable "override_names" {
  description = <<EOT
    Configuration for overriding default resource names.

    - global_prefix: Prefix used for naming all AWS resources created by this module
    - runner_group_name: Override the default StackGuardian runner group name. If not provided, uses {global_prefix}-runner-group-{account_id}
    - connector_name: Override the default StackGuardian connector name. If not provided, uses {global_prefix}-private-runner-backend-{account_id}
  EOT
  type = object({
    global_prefix     = string
    runner_group_name = optional(string, "")
    connector_name    = optional(string, "")
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
    - private_subnet_id: Private subnet ID (optional). If specified, instances will be deployed in private subnet
    - public_subnet_id: Public subnet ID (required). Used for NAT Gateway if private subnet is specified
    - associate_public_ip: Whether to assign public IP to instances
    - create_network_infrastructure: Whether to create NAT Gateway and route tables for private subnet connectivity.
      Defaults to false to support enterprise environments with existing network infrastructure.
      Set to true if you need the module to create NAT Gateway and routing for private subnet internet access.
      When disabled, ensure private subnet has proper routing to internet for StackGuardian platform connectivity.
  EOT
  type = object({
    vpc_id                        = string
    private_subnet_id             = optional(string, "")
    public_subnet_id              = string
    associate_public_ip           = optional(bool, false)
    create_network_infrastructure = optional(bool, false)
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

  validation {
    condition = alltrue([
      for cidr in values(var.firewall.ssh_access_rules) : can(regex("^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}/[0-9]{1,2}$", cidr))
    ])
    error_message = "All SSH access rule values must be valid CIDR blocks (e.g., '10.0.0.0/16')."
  }

  validation {
    condition = alltrue([
      for rule in values(var.firewall.additional_ingress_rules) :
      rule.port >= 1 && rule.port <= 65535
    ])
    error_message = "All additional ingress rule ports must be between 1 and 65535."
  }

  validation {
    condition = alltrue([
      for rule in values(var.firewall.additional_ingress_rules) :
      contains(["tcp", "udp", "icmp"], rule.protocol)
    ])
    error_message = "All additional ingress rule protocols must be one of: tcp, udp, icmp."
  }

  validation {
    condition = alltrue([
      for rule in values(var.firewall.additional_ingress_rules) :
      alltrue([
        for cidr in rule.cidr_blocks : can(regex("^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}/[0-9]{1,2}$", cidr))
      ])
    ])
    error_message = "All CIDR blocks in additional ingress rules must be valid CIDR notation (e.g., '10.0.0.0/16')."
  }
}

/*-----------------------------------+
 | Lambda Autoscaling Variables     |
 +-----------------------------------*/
variable "image" {
  description = "Docker image for the Lambda function that scales the Auto Scaling Group"
  type = object({
    repository = string
    tag        = string
  })

  default = {
    repository = "790543352839.dkr.ecr.eu-central-1.amazonaws.com/private-runner/autoscaler"
    tag        = "94db8a6-dirty"
  }
}

variable "scaling" {
  description = "Auto scaling configuration for the Private Runner"
  type = object({
    scale_out_cooldown_duration = optional(number, 4)
    scale_in_cooldown_duration  = optional(number, 5)
    scale_out_threshold         = optional(number, 3)
    scale_in_threshold          = optional(number, 1)
    scale_in_step               = optional(number, 1)
    scale_out_step              = optional(number, 1)
    min_runners                 = optional(number, 1)
  })
  default = {
    scale_out_cooldown_duration = 4
    scale_in_cooldown_duration  = 5
    scale_out_threshold         = 3
    scale_in_threshold          = 1
    scale_in_step               = 1
    scale_out_step              = 1
    min_runners                 = 1
  }

  validation {
    condition     = var.scaling.scale_out_cooldown_duration >= 4
    error_message = "The scale_out_cooldown_duration must be at least 4 minutes."
  }

  validation {
    condition     = var.scaling.scale_in_threshold >= 1
    error_message = "The scale_in_threshold must be at least 1."
  }

  validation {
    condition     = var.scaling.scale_in_step >= 1
    error_message = "The scale_in_step must be at least 1."
  }

  validation {
    condition     = var.scaling.scale_out_step >= 1
    error_message = "The scale_out_step must be at least 1."
  }

  validation {
    condition     = var.scaling.min_runners >= 1
    error_message = "The min_runners must be at least 1."
  }
}
