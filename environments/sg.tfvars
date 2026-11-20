policy_assignments = {
  asc_default = {
    name                 = "SecurityCenterBuiltIn"
    scope                = "/subscriptions/618c8e34-b87b-44e8-bb3a-b2de95df60ed"
    policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8"
    description          = "This is the default set of policies monitored by Azure Security Center. It was automatically assigned as part of onboarding to Security Center. The default assignment contains only audit policies. For more information please visit https://aka.ms/ascpolicies"
    display_name         = "ASC Default (subscription: 618c8e34-b87b-44e8-bb3a-b2de95df60ed)"
  }
}
