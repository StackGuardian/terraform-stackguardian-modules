api_key = "sgu-1234567890abcdef"
org_name = "test-org"

workflow_groups = ["TeamX-Dev","TeamX-Test", "TeamX-Staging","TeamX-Prod"]

cloud_connectors =    [{
      name = "aws-connector-1"
      connector_type = "AWS_RBAC" #connector_type = "AWS_STATIC" #AWS_STATIC, AWS_RBAC, AWS_OIDC, AZURE_STATIC, AZURE_OIDC, GCP_STATIC
      role_arn = "arn:aws:iam::123456789012:role/StackGuardianRole"
      aws_role_external_id = "test-org:1234567"
    } ]
vcs_connectors = {
    vcs_bitbucket = {
      kind   = "BITBUCKET_ORG"
      name   = "bitbucket-connector"
      config = [{
        bitbucket_creds = {
          bitbucket_creds = "username:token"
        }
      }]
    }
  }
template_list = ["opentofu-aws-vpc"] #add any templates that you need to attach to the role

user_or_group = "user@stackguardian.com"
entity_type = "EMAIL" #Valid values: "EMAIL" or "GROUP"
role_name = "TeamX-Role"


#cloud_connector_name = ""
#account_number = 123456789012 #12 digit aws account number
#region = "eu-central-1"
#aws_policy = "arn:aws:iam::aws:policy/ReadOnlyAccess" #If any specific policy is needed, can be added here

