region = "eu-central-1"
api_key = "sgu_example_apikey"
org_name = "wicked-hop"
workflow_group_name = "test"
account_number = 123456789012 #12 digit aws account number
url = "https://api.app.stackguardian.io"
role_name = ""
aws_policy = "arn:aws:iam::aws:policy/ReadOnlyAccess" #If any specific policy is needed, can be added here
cloud_connector_name = ""

connector_type = "AWS_STATIC" #AWS_STATIC, AWS_RBAC, AWS_OIDC, AZURE_STATIC, AZURE_OIDC, GCP_STATIC

stackguardian_connector_vcs_name = "test-new-gitlab"

#The type of StackGuardian VCS connector is needed, can be filled with corresponding credentials and others can be left empty
#for example just added the gitlab credentials and others are commented out. Just add the corresponding data as per your requirement
gitlab_creds = {
            gitlabCreds =  "gitlabusernew:gitlab_pat"
            gitlabHttpUrl =  "https://gitlab.com"
            gitlabApiUrl =  "https://gitlab.com/v4"
}

github_creds = {
  # github_com_url  = "https://github.com"
  # github_http_url = "" 
}

bitbucket_creds = {}

workflow_group = ["test-new-delete-post-testing"] #add any other workkflow groups that you need to attach to the role
cloud_connector = ["aws-oidc-new-connect-test"] #add any other cloud connector that you need to attach to the role
stackguardian_connector_vcs = ["test-new-gitlab"] #add any other Stackguardian VCS connector that you need to attach to the role
template_list = ["terraform-aws-vpc-stripped"] #add any templates that you need to attach to the role

user_or_group = "user@stackguardian.com"
entity_type = "EMAIL" #Valid values: "EMAIL" or "GROUP"