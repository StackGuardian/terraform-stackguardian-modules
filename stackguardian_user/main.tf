resource "null_resource" "test" {
  provisioner "local-exec" {
    command = <<EOT
    curl --location 'https://api.app.stackguardian.io/api/v1/orgs/${org_name}/invite_user/' \
--header 'Content-Type: application/json' \
--header 'Authorization: apikey ${var.api_key}' \
--data '{
  "userId": "${var.group_or_user}",
  "role": "${var.group_or_user}"
}'
    EOT
  }
}
