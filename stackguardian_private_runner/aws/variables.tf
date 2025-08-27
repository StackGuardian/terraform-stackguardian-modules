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
}

/*-------------------+
 | General Variables |
 +-------------------*/
variable "aws_region" {
  description = "The target AWS Region to setup Private Runner"
  type        = string
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
    org_name = optional(string, null)
  })
}

# variable "sg_api_uri" {
#   description = "The API URI used for authenticating with StackGuardian Platform"
#   type        = string
# }

variable "override_names" {
  description = "Configuration for overriding default resource names"
  type = object({
    global_prefix     = optional(string, "SG_RUNNER")
    runner_group_name = optional(string, "")
    connector_name    = optional(string, "")
  })
  default = {}
}

/*-----------------------+
 | EC2 Network Variables |
 +-----------------------*/
variable "network" {
  description = "Network configuration for the Private Runner instance"
  type = object({
    vpc_id              = string
    private_subnet_id   = optional(string, null)
    public_subnet_id    = string
    associate_public_ip = optional(bool, true)
  })
}

/*-----------------------+
 | EC2 Storage Variables |
 +-----------------------*/
variable "volume" {
  description = "EBS volume configuration for the Private Runner instance"
  type = object({
    type                  = optional(string, "gp3")
    size                  = optional(number, 100)
    delete_on_termination = optional(bool, false)
  })
  default = {}
}

/*------------------------------+
 | EC2 SSH Connection Variables |
 +------------------------------*/
variable "firewall" {
  description = "Firewall and SSH configuration for the Private Runner instance"
  type = object({
    ssh_key_name          = optional(string, "")
    ssh_public_key        = optional(string, "")
    allow_ssh_cidr_blocks = optional(list(string), [])
    additional_ingress_rules = optional(list(object({
      port        = number
      protocol    = string
      cidr_blocks = list(string)
      description = optional(string, "Additional ingress rule")
    })), [])
  })
  default = {}
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
    tag        = "latest"
  }
}

variable "scaling" {
  description = "Auto scaling configuration for the Private Runner"
  type = object({
    scale_out_cooldown_duration = optional(number, 3)
    scale_in_cooldown_duration  = optional(number, 5)
    scale_out_threshold         = optional(number, 5)
    scale_in_threshold          = optional(number, 2)
    scale_in_step               = optional(number, 1)
    scale_out_step              = optional(number, 1)
    min_runners                 = optional(number, 1)
  })
  default = {}
}

