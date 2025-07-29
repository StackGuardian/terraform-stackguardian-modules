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

/*------------------------+
 | EC2 Required Variables |
 +------------------------*/
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

variable "ssh_key_name" {
  description = "The SSH Key Name for the Private Runner instance"
  type        = string
}

variable "instance_type" {
  description = "The EC2 instance type for Private Runner (min 4 vCPU, 8GB RAM recommended)"
  type        = string
  default     = "t3.medium"
}

variable "os_family" {
  description = "The OS family for Private Runner instance: 'amazon', 'ubuntu', or 'rhel'"
  type        = string
  default     = "ubuntu"

  validation {
    condition     = contains(["amazon", "ubuntu", "rhel"], var.os_family)
    error_message = "The os_family must be one of 'amazon', 'ubuntu', or 'rhel'."
  }
}

variable "os_version" {
  description = "Specific OS version (e.g., '20.04' for Ubuntu, '8.5' for RHEL)"
  type        = string
  default     = "22.04"
}

variable "ami_id" {
  description = "The AMI ID for the Private Runner instance with pre-installed dependencies. If not provided, it will be fetched based on the OS family and version and dependencies will be installed in user-data."
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
  default     = 2
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
  default     = "2"
}

variable "scale_in_cooldown_duration" {
  description = "Scale in cooldown duration in minutes"
  type        = string
  default     = "2"
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
