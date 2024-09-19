resource "null_resource" "test" {
  provisioner "local-exec" {
    command = <<EOT
    curl --location 'https://api.app.stackguardian.io/api/v1/orgs/wicked-hop/invite_user/' \
--header 'Content-Type: application/json' \
--header 'Authorization: apikey sgu_qJ3xuMzPCO9S21u7o2XOZ' \
--data '{
  "userId": "ttt/thisismygroup",
  "role": "test"
}'
    EOT
  }
}
