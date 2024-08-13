resource "stackguardian_connector_cloud" "sg-aws-static-connector" {
  data = jsonencode({
    "ResourceName" : var.connector,
    "Tags" : ["tf-provider-example", "onboarding"]
    "Description" : "Onboarding example  of terraform-provider-stackguardian for ConnectorCloud",
    "Settings" : {
      "kind" : "AWS_STATIC",
      "config" : [
        {
          "awsAccessKeyId" : var.awsaccesskey
          "awsSecretAccessKey" : var.awssecretaccesskey
          "awsDefaultRegion" : var.region
        }
      ]
    }
  })
}
