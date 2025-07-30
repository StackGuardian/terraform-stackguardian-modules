/*-------------------+
 | General Variables |
 +-------------------*/
variable "aws_region" {
  description = "The target AWS Region to setup Private Runner"
  type        = string
}

/*------------------------+
 | EC2 Required Variables |
 +------------------------*/
variable "vpc_id" {
  description = "Existing VPC ID for the Private Runner instance"
  type        = string
}

variable "public_subnet_id" {
  description = "Existing Public Subnet ID for the Private Runner instance"
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
  default     = "amazon"

  validation {
    condition     = contains(["amazon", "ubuntu", "rhel"], var.os_family)
    error_message = "The os_family must be one of 'amazon', 'ubuntu', or 'rhel'."
  }
}

variable "os_version" {
  description = "Specific OS version (e.g., '20.04' for Ubuntu, '8.5' for RHEL)"
  type        = string
  default     = ""
}

/*----------------------------------+
 | Packer AMI Machine Image Builder |
 +----------------------------------*/
variable "packer_version" {
  description = "The version of Packer to use for building the machine image"
  type        = string
  default     = "1.13.1"
}

variable "user_script" {
  description = "Custom user script to inject in user data"
  type        = string
  default     = ""
}

variable "terraform_version" {
  description = "The Terraform version to be preinstalled on machine image"
  type        = string
  default     = "1.12.1"
}
