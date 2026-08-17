locals {
  workflow_group_paths           = flatten([for group in var.workflow_groups : [group, "${group}/.*"]])
  workflow_wildcard_paths        = [for path in local.workflow_group_paths : ".*"]
  connector_paths                = concat(var.cloud_connectors, var.vcs_connectors)
  connector_group_wildcard_paths = [for connector in local.connector_paths : ".*"]
  template_paths                 = var.template_list
  template_wildcard_paths        = [for template in local.template_paths : ".*"]

  workflow_permissions = length(var.workflow_groups) == 0 ? {} : {
    "GET/api/v1/orgs/${var.org_name}/wfgrps/<wfGrp>/"                                                                = { name = "GetWorkflowGroup", paths = { "<wfGrp>" = local.workflow_group_paths } }
    "PATCH/api/v1/orgs/${var.org_name}/wfgrps/<wfGrp>/"                                                              = { name = "UpdateWorkflowGroup", paths = { "<wfGrp>" = local.workflow_group_paths } }
    "DELETE/api/v1/orgs/${var.org_name}/wfgrps/<wfGrp>/"                                                             = { name = "DeleteWorkflowGroup", paths = { "<wfGrp>" = local.workflow_group_paths } }
    "POST/api/v1/orgs/${var.org_name}/wfgrps/<wfGrp>/wfgrps/"                                                        = { name = "CreateNestedWorkflowGroup", paths = { "<wfGrp>" = local.workflow_group_paths } }
    "POST/api/v1/orgs/${var.org_name}/wfgrps/<wfGrp>/wfs/"                                                           = { name = "CreateWorkflow", paths = { "<wfGrp>" = local.workflow_group_paths } }
    "GET/api/v1/orgs/${var.org_name}/wfgrps/<wfGrp>/wfs/<wf>/"                                                       = { name = "GetWorkflow", paths = { "<wfGrp>" = local.workflow_group_paths, "<wf>" = local.workflow_wildcard_paths } }
    "PATCH/api/v1/orgs/${var.org_name}/wfgrps/<wfGrp>/wfs/<wf>/"                                                     = { name = "UpdateWorkflow", paths = { "<wfGrp>" = local.workflow_group_paths, "<wf>" = local.workflow_wildcard_paths } }
    "DELETE/api/v1/orgs/${var.org_name}/wfgrps/<wfGrp>/wfs/<wf>/"                                                    = { name = "DeleteWorkflow", paths = { "<wfGrp>" = local.workflow_group_paths, "<wf>" = local.workflow_wildcard_paths } }
    "POST/api/v1/orgs/${var.org_name}/wfgrps/<wfGrp>/wfs/<wf>/wfruns/"                                               = { name = "CreateWorkflowRun", paths = { "<wfGrp>" = local.workflow_group_paths, "<wf>" = local.workflow_wildcard_paths } }
    "GET/api/v1/orgs/${var.org_name}/wfgrps/<wfGrp>/wfs/<wf>/wfruns/<wfRun>/"                                        = { name = "GetWorkflowRun", paths = { "<wfGrp>" = local.workflow_group_paths, "<wf>" = local.workflow_wildcard_paths, "<wfRun>" = local.workflow_wildcard_paths } }
    "DELETE/api/v1/orgs/${var.org_name}/wfgrps/<wfGrp>/wfs/<wf>/wfruns/<wfRun>/"                                     = { name = "UpdateWorkflowRun", paths = { "<wfGrp>" = local.workflow_group_paths, "<wf>" = local.workflow_wildcard_paths, "<wfRun>" = local.workflow_wildcard_paths } }
    "POST/api/v1/orgs/${var.org_name}/wfgrps/<wfGrp>/wfs/<wf>/wfruns/<wfRun>/resume/"                                = { name = "ResumeWorkflowRun", paths = { "<wfGrp>" = local.workflow_group_paths, "<wf>" = local.workflow_wildcard_paths, "<wfRun>" = local.workflow_wildcard_paths } }
    "GET/api/v1/orgs/${var.org_name}/wfgrps/<wfGrp>/wfs/<wf>/wfruns/<wfRun>/logs/"                                   = { name = "GetWorkflowRunLogs", paths = { "<wfGrp>" = local.workflow_group_paths, "<wf>" = local.workflow_wildcard_paths, "<wfRun>" = local.workflow_wildcard_paths } }
    "GET/api/v1/orgs/${var.org_name}/wfgrps/<wfGrp>/wfs/<wf>/wfruns/<wfRun>/wfrunfacts/<wfRunFacts>/"                = { name = "GetWorkflowRunFact", paths = { "<wfGrp>" = local.workflow_group_paths, "<wf>" = local.workflow_wildcard_paths, "<wfRun>" = local.workflow_wildcard_paths, "<wfRunFacts>" = local.workflow_wildcard_paths } }
    "GET/api/v1/orgs/${var.org_name}/wfgrps/<wfGrp>/wfs/<wf>/outputs/"                                               = { name = "GetWorkflowOutputs", paths = { "<wfGrp>" = local.workflow_group_paths, "<wf>" = local.workflow_wildcard_paths } }
    "GET/api/v1/orgs/${var.org_name}/wfgrps/<wfGrp>/wfs/<wf>/listall_artifacts/"                                     = { name = "ListWorkflowArtifacts", paths = { "<wfGrp>" = local.workflow_group_paths, "<wf>" = local.workflow_wildcard_paths } }
    "GET/api/v1/orgs/${var.org_name}/wfgrps/<wfGrp>/wfs/<wf>/artifacts/<artifact>/"                                  = { name = "GetWorkflowArtifact", paths = { "<wfGrp>" = local.workflow_group_paths, "<wf>" = local.workflow_wildcard_paths, "<artifact>" = local.workflow_wildcard_paths } }
    "PATCH/api/v1/orgs/${var.org_name}/wfgrps/<wfGrp>/wfs/<wf>/artifacts/<artifact>/"                                = { name = "CreateUpdateDeleteWorkflowArtifact", paths = { "<wfGrp>" = local.workflow_group_paths, "<wf>" = local.workflow_wildcard_paths, "<artifact>" = local.workflow_wildcard_paths } }
    "POST/api/v1/orgs/${var.org_name}/wfgrps/<wfGrp>/stacks/"                                                        = { name = "CreateStack", paths = { "<wfGrp>" = local.workflow_group_paths } }
    "GET/api/v1/orgs/${var.org_name}/wfgrps/<wfGrp>/stacks/<stack>/"                                                 = { name = "GetStack", paths = { "<wfGrp>" = local.workflow_group_paths, "<stack>" = local.workflow_wildcard_paths } }
    "PATCH/api/v1/orgs/${var.org_name}/wfgrps/<wfGrp>/stacks/<stack>/"                                               = { name = "UpdateStack", paths = { "<wfGrp>" = local.workflow_group_paths, "<stack>" = local.workflow_wildcard_paths } }
    "DELETE/api/v1/orgs/${var.org_name}/wfgrps/<wfGrp>/stacks/<stack>/"                                              = { name = "DeleteStack", paths = { "<wfGrp>" = local.workflow_group_paths, "<stack>" = local.workflow_wildcard_paths } }
    "POST/api/v1/orgs/${var.org_name}/wfgrps/<wfGrp>/stacks/<stack>/stackruns/"                                      = { name = "CreateStackRun", paths = { "<wfGrp>" = local.workflow_group_paths, "<stack>" = local.workflow_wildcard_paths } }
    "GET/api/v1/orgs/${var.org_name}/wfgrps/<wfGrp>/stacks/<stack>/stackruns/<stackRun>/"                            = { name = "GetStackRun", paths = { "<wfGrp>" = local.workflow_group_paths, "<stack>" = local.workflow_wildcard_paths, "<stackRun>" = local.workflow_wildcard_paths } }
    "GET/api/v1/orgs/${var.org_name}/wfgrps/<wfGrp>/stacks/<stack>/outputs/"                                         = { name = "GetStackOutputs", paths = { "<wfGrp>" = local.workflow_group_paths, "<stack>" = local.workflow_wildcard_paths } }
    "POST/api/v1/orgs/${var.org_name}/wfgrps/<wfGrp>/stacks/<stack>/wfs/<wf>/wfruns/<wfRun>/resume/"                 = { name = "ResumeStackWorkflowRun", paths = { "<wfGrp>" = local.workflow_group_paths, "<stack>" = local.workflow_wildcard_paths, "<wf>" = local.workflow_wildcard_paths, "<wfRun>" = local.workflow_wildcard_paths } }
    "GET/api/v1/orgs/${var.org_name}/wfgrps/<wfGrp>/stacks/<stack>/wfs/<wf>/"                                        = { name = "GetStackWorkflow", paths = { "<wfGrp>" = local.workflow_group_paths, "<stack>" = local.workflow_wildcard_paths, "<wf>" = local.workflow_wildcard_paths } }
    "PATCH/api/v1/orgs/${var.org_name}/wfgrps/<wfGrp>/stacks/<stack>/wfs/<wf>/"                                      = { name = "UpdateStackWorkflow", paths = { "<wfGrp>" = local.workflow_group_paths, "<stack>" = local.workflow_wildcard_paths, "<wf>" = local.workflow_wildcard_paths } }
    "DELETE/api/v1/orgs/${var.org_name}/wfgrps/<wfGrp>/stacks/<stack>/wfs/<wf>/"                                     = { name = "DeleteStackWorkflow", paths = { "<wfGrp>" = local.workflow_group_paths, "<stack>" = local.workflow_wildcard_paths, "<wf>" = local.workflow_wildcard_paths } }
    "GET/api/v1/orgs/${var.org_name}/wfgrps/<wfGrp>/stacks/<stack>/wfs/<wf>/wfruns/<wfRun>/"                         = { name = "GetStackWorkflowRun", paths = { "<wfGrp>" = local.workflow_group_paths, "<stack>" = local.workflow_wildcard_paths, "<wf>" = local.workflow_wildcard_paths, "<wfRun>" = local.workflow_wildcard_paths } }
    "GET/api/v1/orgs/${var.org_name}/wfgrps/<wfGrp>/stacks/<stack>/wfs/<wf>/wfruns/<wfRun>/logs/"                    = { name = "GetStackWorkflowRunLogs", paths = { "<wfGrp>" = local.workflow_group_paths, "<stack>" = local.workflow_wildcard_paths, "<wf>" = local.workflow_wildcard_paths, "<wfRun>" = local.workflow_wildcard_paths } }
    "GET/api/v1/orgs/${var.org_name}/wfgrps/<wfGrp>/stacks/<stack>/wfs/<wf>/wfruns/<wfRun>/wfrunfacts/<wfRunFacts>/" = { name = "GetStackWorkflowRunFact", paths = { "<wfGrp>" = local.workflow_group_paths, "<stack>" = local.workflow_wildcard_paths, "<wf>" = local.workflow_wildcard_paths, "<wfRun>" = local.workflow_wildcard_paths, "<wfRunFacts>" = local.workflow_wildcard_paths } }
    "GET/api/v1/orgs/${var.org_name}/wfgrps/<wfGrp>/stacks/<stack>/wfs/<wf>/outputs/"                                = { name = "GetStackWorkflowOutputs", paths = { "<wfGrp>" = local.workflow_group_paths, "<stack>" = local.workflow_wildcard_paths, "<wf>" = local.workflow_wildcard_paths } }
    "GET/api/v1/orgs/${var.org_name}/wfgrps/<wfGrp>/stacks/<stack>/wfs/<wf>/listall_artifacts/"                      = { name = "ListStackWorkflowArtifacts", paths = { "<wfGrp>" = local.workflow_group_paths, "<stack>" = local.workflow_wildcard_paths, "<wf>" = local.workflow_wildcard_paths } }
    "GET/api/v1/orgs/${var.org_name}/wfgrps/<wfGrp>/stacks/<stack>/wfs/<wf>/artifacts/<artifact>/"                   = { name = "GetStackWorkflowArtifact", paths = { "<wfGrp>" = local.workflow_group_paths, "<stack>" = local.workflow_wildcard_paths, "<wf>" = local.workflow_wildcard_paths, "<artifact>" = local.workflow_wildcard_paths } }
    "PATCH/api/v1/orgs/${var.org_name}/wfgrps/<wfGrp>/stacks/<stack>/wfs/<wf>/artifacts/<artifact>/"                 = { name = "CreateUpdateDeleteStackWorkflowArtifact", paths = { "<wfGrp>" = local.workflow_group_paths, "<stack>" = local.workflow_wildcard_paths, "<wf>" = local.workflow_wildcard_paths, "<artifact>" = local.workflow_wildcard_paths } }
  }

  connector_permissions = length(local.connector_paths) == 0 ? {} : {
    "GET/api/v1/orgs/${var.org_name}/integrations/<integration>/"                                         = { name = "GetIntegration", paths = { "<integration>" = local.connector_paths } }
    "PATCH/api/v1/orgs/${var.org_name}/integrations/<integration>/"                                       = { name = "UpdateIntegration", paths = { "<integration>" = local.connector_paths } }
    "DELETE/api/v1/orgs/${var.org_name}/integrations/<integration>/"                                      = { name = "DeleteIntegration", paths = { "<integration>" = local.connector_paths } }
    "GET/api/v1/orgs/${var.org_name}/integrationgroups/<integrationgroup>/integrations/<integration>/"    = { name = "GetIntegrationGroupChild", paths = { "<integrationgroup>" = local.connector_group_wildcard_paths, "<integration>" = local.connector_paths } }
    "PATCH/api/v1/orgs/${var.org_name}/integrationgroups/<integrationgroup>/integrations/<integration>/"  = { name = "UpdateIntegrationGroupChild", paths = { "<integrationgroup>" = local.connector_group_wildcard_paths, "<integration>" = local.connector_paths } }
    "DELETE/api/v1/orgs/${var.org_name}/integrationgroups/<integrationgroup>/integrations/<integration>/" = { name = "DeleteIntegrationGroupChild", paths = { "<integrationgroup>" = local.connector_group_wildcard_paths, "<integration>" = local.connector_paths } }
  }

  template_permissions = length(local.template_paths) == 0 ? {} : {
    "GET/api/v1/templatetypes/<templateType>/<org>/<template>/"    = { name = "GetTemplate", paths = { "<templateType>" = local.template_wildcard_paths, "<org>" = local.template_wildcard_paths, "<template>" = local.template_paths } }
    "PATCH/api/v1/templatetypes/<templateType>/<org>/<template>/"  = { name = "UpdateTemplate", paths = { "<templateType>" = local.template_wildcard_paths, "<org>" = local.template_wildcard_paths, "<template>" = local.template_paths } }
    "DELETE/api/v1/templatetypes/<templateType>/<org>/<template>/" = { name = "DeleteTemplate", paths = { "<templateType>" = local.template_wildcard_paths, "<org>" = local.template_wildcard_paths, "<template>" = local.template_paths } }
  }

  team_onboarding_permissions = merge(local.workflow_permissions, local.connector_permissions, local.template_permissions)
}
