


resource "stackguardian_role" "ONBOARDING-Project01-Developer" {
  data = jsonencode({
    "ResourceName" : "ONBOARDING-Project01-Developer",
    //"Description" : "Onboarding example of terraform-provider-stackguardian for Role Developer",
    "Tags" : ["tf-provider-example", "onboarding"],
    "Actions" : [
      "wicked-hop",
    ],
    "AllowedPermissions" : {

      // WF-GROUP
      "GET/api/v1/orgs/wicked-hop/wfgrps/<wfGrp>/" : {
        "name" : "GetWorkflowGroup",
        "paths" : {
          "<wfGrp>" : [
            "ONBOARDING-Project01-Frontend",
            "ONBOARDING-Project01-Backend",
            "ONBOARDING-Project01-DevOps"
          ]
        }
      }
    }
  })
}