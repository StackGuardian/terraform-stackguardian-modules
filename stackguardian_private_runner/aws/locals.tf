data "external" "env" {
  program = [
    "sh",
    "-c",
    "echo '{\"sg_org_name\": \"'$${SG_ORG_ID##*/}'\", \"sg_api_uri\": \"'$${SG_API_URI:-https://api.app.stackguardian.io}'\"}'"
  ]
}


locals {
  sg_org_name = (
    var.sg_org_name != null
    ? var.sg_org_name
    : data.external.env.result.sg_org_name
  )
  sg_api_uri = data.external.env.result.sg_api_uri
}
