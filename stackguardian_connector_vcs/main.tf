check "github_com" {
  assert {
    condition = var.vcs_connectors != "GITHUB_COM" || (
      var.github_com_url != null &&
      var.github_http_url != null
    )

    error_message = "Variables github_com_url and github_http_url must be set when vcs_connectors is GITHUB_COM."
  }
}

resource "stackguardian_connector" "sg_github_com_connector" {
  count         = var.vcs_connectors == "GITHUB_COM" ? 1 : 0
  resource_name = var.vcs_connector_name

  description = "Onboarding example of terraform-provider-stackguardian for GitHub.com VCS Connector"

  settings = {
    kind = var.vcs_connectors

    config = [{
      github_com_url  = var.github_com_url
      github_http_url = var.github_http_url
    }]
  }
}

check "github_app_custom" {
  assert {
    condition = var.vcs_connectors != "GITHUB_APP_CUSTOM" || (
      var.github_app_client_id != null &&
      var.github_app_client_secret != null &&
      var.github_app_id != null &&
      var.github_app_pem_file_content != null &&
      var.github_app_webhook_secret != null &&
      var.github_app_webhook_url != null
    )

    error_message = "Variables github_app_client_id, github_app_client_secret, github_app_id, github_app_pem_file_content, github_app_webhook_secret, and github_app_webhook_url must be set when vcs_connectors is GITHUB_APP_CUSTOM."
  }
}

resource "stackguardian_connector" "sg_github_app_custom_connector" {
  count         = var.vcs_connectors == "GITHUB_APP_CUSTOM" ? 1 : 0
  resource_name = var.vcs_connector_name

  description = "Onboarding example of terraform-provider-stackguardian for GitHub App Custom VCS Connector"

  settings = {
    kind = var.vcs_connectors

    config = [{
      github_app_client_id        = var.github_app_client_id
      github_app_client_secret    = var.github_app_client_secret
      github_app_id               = var.github_app_id
      github_app_pem_file_content = var.github_app_pem_file_content
      github_app_webhook_secret   = var.github_app_webhook_secret
      github_app_webhook_url      = var.github_app_webhook_url
    }]
  }
}

check "bitbucket_org" {
  assert {
    condition = var.vcs_connectors != "BITBUCKET_ORG" || (
      var.bitbucket_creds != null
    )

    error_message = "Variable bitbucket_creds must be set when vcs_connectors is BITBUCKET_ORG."
  }
}

resource "stackguardian_connector" "sg_bitbucket_org_connector" {
  count         = var.vcs_connectors == "BITBUCKET_ORG" ? 1 : 0
  resource_name = var.vcs_connector_name

  description = "Onboarding example of terraform-provider-stackguardian for Bitbucket Organization VCS Connector"

  settings = {
    kind = var.vcs_connectors

    config = [{
      bitbucket_creds = var.bitbucket_creds
    }]
  }
}

check "gitlab_com" {
  assert {
    condition = var.vcs_connectors != "GITLAB_COM" || (
      var.gitlab_api_url != null &&
      var.gitlab_creds != null &&
      var.gitlab_http_url != null
    )

    error_message = "Variables gitlab_api_url, gitlab_creds, and gitlab_http_url must be set when vcs_connectors is GITLAB_COM."
  }
}

resource "stackguardian_connector" "sg_gitlab_com_connector" {
  count         = var.vcs_connectors == "GITLAB_COM" ? 1 : 0
  resource_name = var.vcs_connector_name

  description = "Onboarding example of terraform-provider-stackguardian for GitLab.com VCS Connector"

  settings = {
    kind = var.vcs_connectors

    config = [{
      gitlab_api_url  = var.gitlab_api_url
      gitlab_creds    = var.gitlab_creds
      gitlab_http_url = var.gitlab_http_url
    }]
  }
}

check "azure_devops" {
  assert {
    condition = var.vcs_connectors != "AZURE_DEVOPS" || (
      var.azure_devops_api_url != null &&
      var.azure_devops_http_url != null &&
      var.azure_creds != null
    )

    error_message = "Variables azure_devops_api_url, azure_devops_http_url, and azure_creds must be set when vcs_connectors is AZURE_DEVOPS."
  }
}

resource "stackguardian_connector" "sg_azure_devops_connector" {
  count         = var.vcs_connectors == "AZURE_DEVOPS" ? 1 : 0
  resource_name = var.vcs_connector_name

  description = "Onboarding example of terraform-provider-stackguardian for Azure DevOps VCS Connector"

  settings = {
    kind = var.vcs_connectors

    config = [{
      azure_devops_api_url  = var.azure_devops_api_url
      azure_devops_http_url = var.azure_devops_http_url
      azure_creds           = var.azure_creds
    }]
  }
}

# check "aws_rbac_vars" {
#   assert {
#     condition     = var.vcs_connectors!= "AWS_RBAC" || (var.role_arn != null && var.role_external_id != null)
#     error_message = "Variables role_arn and role_external_id must be set when vcs_connectorsis AWS_RBAC."
#   }
# }

# resource "stackguardian_connector" "sg_aws_rbac_connector" {
#   count         = (var.vcs_connectors== "AWS_RBAC") ? 1 : 0
#   resource_name = var.cloud_connector_name
#   description   = "Onboarding an AWS Role with RBAC"
#   settings = {
#     kind = var.connector_type,
#     config = [{
#       role_arn         = var.role_arn
#       external_id      = var.role_external_id
#       duration_seconds = 3600
#     }]
#   }
# }

# check "azure_static_vars" {
#   assert {
#     condition     = var.vcs_connectors!= "AZURE_STATIC" || (var.armTenantId != null && var.armSubscriptionId != null && var.armClientId != null && var.armClientSecret != null)
#     error_message = "Variables armTenantId, armSubscriptionId, armClientId, and armClientSecret must be set when vcs_connectorsis AZURE_STATIC."
#   }
# }

# resource "stackguardian_connector" "sg_azure_static_connector" {
#   count         = (var.vcs_connectors== "AZURE_STATIC") ? 1 : 0
#   resource_name = var.cloud_connector_name
#   description   = "Onboarding example of terraform-provider-stackguardian for AzureConnectorCloud"
#   settings = {
#     kind = var.connector_type,
#     config = [{
#       arm_tenant_id       = var.armTenantId,
#       arm_subscription_id = var.armSubscriptionId,
#       arm_client_id       = var.armClientId,
#       arm_client_secret   = var.armClientSecret
#     }]
#   }
# }

# check "azure_oidc_vars" {
#   assert {
#     condition     = var.vcs_connectors!= "AZURE_OIDC" || (var.armTenantId != null && var.armSubscriptionId != null && var.armClientId != null)
#     error_message = "Variables armTenantId, armSubscriptionId, and armClientId must be set when vcs_connectorsis AZURE_OIDC."
#   }
# }

# resource "stackguardian_connector" "sg_azure_oidc_connector" {
#   count         = (var.vcs_connectors== "AZURE_OIDC") ? 1 : 0
#   resource_name = var.cloud_connector_name
#   description   = "Onboarding example of terraform-provider-stackguardian for AzureConnectorCloud"
#   settings = {
#     kind = var.connector_type,
#     config = [{
#       arm_tenant_id       = var.armTenantId,
#       arm_subscription_id = var.armSubscriptionId,
#       arm_client_id       = var.armClientId,
#     }]
#   }
# }

# check "gcp_oidc_vars" {
#   assert {
#     condition     = var.vcs_connectors!= "GCP_OIDC" || var.gcp_config_file_content != null
#     error_message = "Variable gcp_config_file_content must be set when vcs_connectorsis GCP_OIDC."
#   }
# }

# resource "stackguardian_connector" "sg_gcp_oidc_connector" {
#   count         = (var.vcs_connectors== "GCP_OIDC") ? 1 : 0
#   resource_name = var.cloud_connector_name
#   description   = "Onboarding example of terraform-provider-stackguardian for AzureConnectorCloud"
#   settings = {
#     kind = var.connector_type,
#     config = [{
#       gcp_config_file_content = var.gcp_config_file_content
#     }]
#   }
# }


# resource "stackguardian_connector" "sg_vcs_connector" {
#   for_each = {
#     for key, value in var.vcs_connectors :
#     key => value if(
#       # Check if any credentials are provided for gitlab, github or bitbucket
#       (
#         (lookup(value.config[0], "gitlab_creds", null) != null) ||
#         (lookup(value.config[0], "github_creds", null) != null) ||
#         (lookup(value.config[0], "bitbucket_creds", null) != null)
#       )
#     )
#   }

#   resource_name = each.value.name
#   description   = "Onboarding VCS connector"

#   settings = {
#     kind = each.value.kind
#     config = flatten([
#       for config_item in each.value.config : {
#         # Dynamically handle different connector types and jsonencode here
#         gitlab_creds    = lookup(config_item, "gitlab_creds", null) != null ? jsonencode(lookup(config_item, "gitlab_creds", null)) : null
#         github_creds    = lookup(config_item, "github_creds", null) != null ? jsonencode(lookup(config_item, "github_creds", null)) : null
#         bitbucket_creds = lookup(config_item, "bitbucket_creds", null) != null ? jsonencode(lookup(config_item, "bitbucket_creds", null)) : null
#       }
#     ])
#   }
# }