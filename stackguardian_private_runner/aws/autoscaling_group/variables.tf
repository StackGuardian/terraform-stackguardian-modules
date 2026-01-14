/*-------------------+
 | Mode Configuration |
 +-------------------*/
variable "create_asg" {
  description = <<EOT
    Whether to create a new Auto Scaling Group.
    Set to false to use an existing ASG and only deploy the Lambda autoscaler.
  EOT
  type        = bool
  default     = true
}

variable "existing_asg_name" {
  description = "Name of an existing Auto Scaling Group (required when create_asg = false)"
  type        = string
  default     = ""
}

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
  default     = ""

  validation {
    condition     = var.ami_id == "" || can(regex("^ami-.*", var.ami_id))
    error_message = "The ami_id must be a valid AMI ID starting with 'ami-' or empty when using existing ASG."
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

    - global_prefix: Prefix used for naming all AWS resources created by this module
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
 | EC2 Network Variables |
 +-----------------------*/
variable "network" {
  description = <<EOT
    Network configuration for the Private Runner instances.

    - vpc_id: Existing VPC ID for deployment
    - subnet_id: Subnet ID for the ASG instances (backwards compatible, use this OR private/public subnet combination)
    - private_subnet_id: Private subnet ID (optional, for private deployments)
    - public_subnet_id: Public subnet ID (required when using NAT Gateway with create_network_infrastructure)
    - associate_public_ip: Whether to assign public IP to instances
    - create_network_infrastructure: Whether to create NAT Gateway and route tables for private subnet connectivity.
      Set to true if you need the module to create NAT Gateway and routing for private subnet internet access.
      When disabled, ensure private subnet has proper routing to internet for StackGuardian platform connectivity.
    - proxy_url: HTTP proxy URL for private network deployments (e.g., http://proxy.example.com:8080)
    - additional_security_group_ids: Additional security group IDs to attach to instances
    - vpc_endpoint_security_group_ids: (Optional) Security group IDs of VPC endpoints (STS, SSM, ECR, etc.).
      An inbound rule will be added to allow HTTPS (443) traffic from the runner's security group.
  EOT
  type = object({
    vpc_id                          = string
    subnet_id                       = optional(string, "")
    private_subnet_id               = optional(string, "")
    public_subnet_id                = optional(string, "")
    associate_public_ip             = optional(bool, false)
    create_network_infrastructure   = optional(bool, false)
    proxy_url                       = optional(string, "")
    additional_security_group_ids   = optional(list(string), [])
    vpc_endpoint_security_group_ids = optional(list(string), [])
  })
  default = {
    vpc_id    = ""
    subnet_id = ""
  }

  validation {
    condition = (
      var.network.subnet_id != "" ||
      var.network.private_subnet_id != "" ||
      var.network.public_subnet_id != ""
    )
    error_message = "At least one subnet must be provided (subnet_id, private_subnet_id, or public_subnet_id)."
  }

  validation {
    condition = (
      !var.network.create_network_infrastructure ||
      (var.network.private_subnet_id != "" && var.network.public_subnet_id != "")
    )
    error_message = "Both private_subnet_id and public_subnet_id are required when create_network_infrastructure is true."
  }
}

/*-----------------------+
 | EC2 Storage Variables |
 +-----------------------*/
variable "volume" {
  description = "EBS volume configuration for the Private Runner instances"
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
  description = "Firewall and SSH configuration for the Private Runner instances"
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
 | Auto Scaling Configuration       |
 +-----------------------------------*/
variable "scaling" {
  description = "Auto scaling configuration for the Private Runner"
  type = object({
    min_size                    = optional(number, 1)
    max_size                    = optional(number, 3)
    desired_capacity            = optional(number, 1)
    scale_out_threshold         = optional(number, 3)
    scale_in_threshold          = optional(number, 1)
    scale_out_step              = optional(number, 1)
    scale_in_step               = optional(number, 1)
    scale_out_cooldown_duration = optional(number, 4)
    scale_in_cooldown_duration  = optional(number, 5)
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

  validation {
    condition     = var.scaling.scale_out_cooldown_duration >= 4
    error_message = "scale_out_cooldown_duration must be at least 4 minutes."
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
