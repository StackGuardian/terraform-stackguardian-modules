/*-------------------+
 | General Variables |
 +-------------------*/
variable "gcp_project_id" {
  description = "The GCP project ID to build the Private Runner image in"
  type        = string
}

variable "gcp_zone" {
  description = "The GCP zone for the Packer build instance"
  type        = string
  default     = "europe-west1-b"
}

variable "instance_type" {
  description = "The GCE machine type for the Packer build process"
  type        = string
  default     = "e2-medium"
}

/*-------------------------------+
 | Image Build Network Settings  |
 +-------------------------------*/
variable "network" {
  description = "Network configuration for the Packer build instance"
  type = object({
    network         = optional(string, "default")
    subnetwork      = optional(string, "default")
    use_internal_ip = optional(bool, false)
    proxy_url       = optional(string, "")
  })
  default = {}
}

/*---------------------------+
 | Operating System Settings |
 +---------------------------*/
variable "os" {
  description = "Operating system configuration for the GCE image"
  type = object({
    image_family             = optional(string, "ubuntu-2204-lts")
    image_project            = optional(string, "ubuntu-os-cloud")
    ssh_username             = optional(string, "")
    update_os_before_install = optional(bool, false)
    user_script              = optional(string, "")
  })
  default = {}
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
    primary_version     = optional(string, "")
    additional_versions = optional(list(string), [])
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
    primary_version     = optional(string, "")
    additional_versions = optional(list(string), [])
  })
  default = {
    primary_version     = ""
    additional_versions = []
  }
}

/*----------------+
 | Disk Settings  |
 +----------------*/
variable "disk" {
  description = "Disk configuration for the GCE image"
  type = object({
    size = optional(number, 20)
    type = optional(string, "pd-balanced")
  })
  default = {}
}
