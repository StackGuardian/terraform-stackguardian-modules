resource "stackguardian_connector_cloud" "sg_aws_static_connector" {
  count = (var.connector_type == "AWS_STATIC") ? 1 : 0
  data = jsonencode({
    "ResourceName" : var.connector_name,
    "Tags" : ["tf-provider-example", "onboarding"]
    "Description" : "AWS Cloud Connector",
    "Settings" : {
      "kind" : var.connector_type,
      "config" : [
        {
          "awsAccessKeyId" : var.aws_access_key_id
          "awsSecretAccessKey" : var.aws_secret_access_key
          "awsDefaultRegion" : var.aws_default_region
        }
      ]
    }
  })
}

resource "stackguardian_connector_cloud" "sg_azure_static_connector" {
  count = (var.connector_type == "AZURE_STATIC") ? 1 : 0
  data = jsonencode({
    "ResourceName" : var.connector_name,
    "Tags" : ["sg-azure-cloud-connector"]
    "Description" : "Azure Cloud Connector",
    "Settings" : {
     "kind": var.connector_type,
    "config": [
      {
        "armTenantId": var.armTenantId,
        "armSubscriptionId": var.armSubscriptionId,
        "armClientId": var.armClientId,
        "armClientSecret": var.armClientSecret
      }
    ]
    }
  })
}
