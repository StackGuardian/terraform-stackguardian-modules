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
}

/*-------------------+
 | General Variables |
 +-------------------*/
variable "aws_region" {
  description = "The target AWS Region to setup Private Runner"
  type        = string
  default     = "eu-central-1"
}

/*-----------------------------------+
 | StackGuardian Resources Variables |
 +-----------------------------------*/
variable "stackguardian" {
  description = "StackGuardian platform configuration and S3 storage backend for Private Runner state storage"
  type = object({
    api_key            = string
    org_name           = optional(string, "")
    api_uri            = optional(string, "")
    runner_group_name  = string
    # runner_group_token = string
    # bucket_name        = string
  })
  sensitive = true
}

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
    - private_subnet_id: Private subnet ID (optional). If specified, instances will be deployed in private subnet
    - public_subnet_id: Public subnet ID (required). Used for NAT Gateway if private subnet is specified
    - security_group_id: Additional security group ID to attach to the instance
    - associate_public_ip: Whether to assign public IP to instances
  EOT
  type = object({
    vpc_id              = string
    private_subnet_id   = optional(string, "")
    public_subnet_id    = string
    security_group_id   = string
    associate_public_ip = optional(bool, false)
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
}

/*-----------------------------------+
 | Runner Startup Variables          |
 +-----------------------------------*/
variable "runner_startup_timeout" {
  description = "Maximum time in seconds to wait for Docker to start before shutting down the instance"
  type        = number
  default     = 300
}
