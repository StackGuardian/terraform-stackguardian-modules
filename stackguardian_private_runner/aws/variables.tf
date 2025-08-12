/*-----------------------------------+
 | StackGuardian Resources Variables |
 +-----------------------------------*/
variable "sg_api_key" {
  description = "Your organization's API key on the StackGuardian Platform"
  type        = string
}

variable "sg_org_name" {
  description = "Your organization name on the StackGuardian Platform"
  type        = string
}

variable "sg_api_uri" {
  description = "The API URI used for authenticating with StackGuardian Platform"
  type        = string
}

/*-------------------+
 | General Variables |
 +-------------------*/
variable "aws_region" {
  description = "The target AWS Region to setup Private Runner"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for naming AWS resources"
  type        = string
  default     = "sg"
}

variable "override_runner_group_name" {
  description = <<EOT
    Optional: Override the default runner group name.
    If not provided, the module will use the default group name: {name_prefix}-runner-group-{account_id}
    This is useful if you want to use a specific runner group name for your organization.
    Default is an empty string, meaning the default group name will be used.
  EOT
  type        = string
  default     = ""
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

/*-----------------------+
 | EC2 Network Variables |
 +-----------------------*/
variable "vpc_id" {
  description = "Existing VPC ID for the Private Runner instance"
  type        = string
}

variable "private_subnet_id" {
  description = "Existing Private Subnet ID for the Private Runner instance"
  type        = string
  default     = null
}

variable "public_subnet_id" {
  description = "Existing Public Subnet ID for the Private Runner instance"
  type        = string
}

variable "associate_public_ip" {
  description = "Whether to assign a public IP to the Private Runner instance"
  type        = bool
  default     = true
}

/*-----------------------+
 | EC2 Storage Variables |
 +-----------------------*/
variable "volume_type" {
  description = "Type of the EBS volume for the Private Runner instance"
  type        = string
  default     = "gp3"
}

variable "volume_size" {
  description = "Size of the EBS volume in GB for the Private Runner instance"
  type        = number
  default     = 100
}

variable "delete_volume_on_termination" {
  description = "Whether to delete the EBS volume on instance termination"
  type        = bool
  default     = false
}

/*------------------------------+
 | EC2 SSH Connection Variables |
 +------------------------------*/
variable "ssh_key_name" {
  description = "The existing SSH key name from AWS. If not provided and ssh_public_key is empty, no SSH key will be configured."
  type        = string
  default     = ""
}

variable "ssh_public_key" {
  description = "Custom SSH public key content to add to the instance. If provided, this takes precedence over ssh_key_name."
  type        = string
  default     = ""
}

variable "allow_ssh_cidr_blocks" {
  description = "CIDR blocks allowed to SSH into the Private Runner instance. If empty, no SSH access is allowed."
  type        = list(string)
  default     = []
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
}

/*-----------------------------------+
 | Auto Scaling Group Variables     |
 +-----------------------------------*/
variable "asg_min_size" {
  description = "Minimum number of instances in the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Maximum number of instances in the Auto Scaling Group"
  type        = number
  default     = 5
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in the Auto Scaling Group"
  type        = number
  default     = 1
}

/*-----------------------------------+
 | Lambda Autoscaling Variables     |
 +-----------------------------------*/
variable "image" {
  description = "Docker image for the Lambda function"
  type = object({
    repository = string
    tag        = string
  })

  default = {
    repository = "790543352839.dkr.ecr.eu-central-1.amazonaws.com/private-runner/autoscaler"
    tag        = "latest"
  }
}

variable "scale_out_cooldown_duration" {
  description = "Scale out cooldown duration in minutes"
  type        = string
  default     = "3"
}

variable "scale_in_cooldown_duration" {
  description = "Scale in cooldown duration in minutes"
  type        = string
  default     = "5"
}

variable "scale_out_threshold" {
  description = "Threshold for scaling out"
  type        = string
  default     = "5"
}

variable "scale_in_threshold" {
  description = "Threshold for scaling in"
  type        = string
  default     = "2"
}

variable "scale_in_step" {
  description = "Number of instances to scale in"
  type        = string
  default     = "1"
}

variable "scale_out_step" {
  description = "Number of instances to scale out"
  type        = string
  default     = "1"
}

variable "min_runners" {
  description = "Minimum number of runners"
  type        = string
  default     = "1"
}
