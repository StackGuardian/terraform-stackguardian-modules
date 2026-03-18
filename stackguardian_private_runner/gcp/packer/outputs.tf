/*-------------------------------------+
 | Packer GCE Machine Image Builder    |
 +-------------------------------------*/
output "image_name" {
  description = "The name of the created GCE image"
  value       = data.external.packer_image_name.result["image_name"]
}

output "image_self_link" {
  description = "The self link of the created GCE image"
  value       = "projects/${var.gcp_project_id}/global/images/${data.external.packer_image_name.result["image_name"]}"
}

output "image_info" {
  description = "Comprehensive GCE image information"
  value = {
    name      = data.external.packer_image_name.result["image_name"]
    project   = var.gcp_project_id
    zone      = var.gcp_zone
    os        = var.os.image_family
    timestamp = formatdate("YYYY-MM-DD-hhmm", timestamp())
  }
}
