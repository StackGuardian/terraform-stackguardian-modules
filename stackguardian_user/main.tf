data "http" "invite_user" {
  url    = "https://api.app.stackguardian.io/api/v1/orgs/${var.org_name}/invite_user/"
  method = "POST"

  request_headers = {
    Content-Type = "application/json"
    Authorization = "apikey ${var.api_key}"
  }

  request_body = jsonencode({
    userId        = var.group_or_user
    role          = var.role_name
  })
}
