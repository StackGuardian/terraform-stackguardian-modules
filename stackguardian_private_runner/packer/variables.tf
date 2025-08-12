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
  description = "Specific OS version (e.g., '22.04' for Ubuntu, '9.6' for RHEL)"
  type        = string
  default     = ""
}

variable "ssh_username" {
  description = "The SSH username for the machine instance."
  type        = string
  default     = null
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

variable "terraform_versions" {
  description = <<-EOT
   List of Terraform versions to be preinstalled on the machine image.
   The versions will be installed to /bin/terraform$\{version\}
   For example: version 1.12.0 will be installed to /bin/terraform1.12.0
  EOT
  type        = list(string)
  default     = ["1.12.0", "1.12.1", "1.12.2"]
}

variable "terraform_version" {
  description = <<-EOT
    The Terraform version to be preinstalled on the machine image.
    This version will be the default version installed to /bin/terraform.
  EOT
  type        = string
  default     = "1.12.1"
}

variable "opentofu_versions" {
  description = <<-EOT
   List of OpenTofu versions to be preinstalled on the machine image.
   The versions will be installed to /bin/tofu$\{version\}
   For example: version 1.12.0 will be installed to /bin/tofu1.12.0
  EOT
  type        = list(string)
  default     = ["1.10.4", "1.9.3"]
}

variable "opentofu_version" {
  description = <<-EOT
    The OpenTofu version to be preinstalled on the machine image.
    This version will be the default version installed to /bin/tofu.
  EOT
  type        = string
  default     = "1.10.5"
}
