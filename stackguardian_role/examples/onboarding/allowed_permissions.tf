locals {
    allowed_permissions = {
        data = jsonencode({
        "AllowedPermissions": {
            "GET/api/v1/orgs/wicked-hop/wfgrps/<wfGrp>/wfs/<wf>/wfruns/<wfRun>/wfrunfacts/<wfRunFacts>/": {
                "name": "GetWorkflowRunFact",
                "paths": {
                    "<wfGrp>": var.wfGrp
                    "<wfRun>": [
                        ".*"
                    ],
                    "<wf>": [
                        ".*"
                    ],
                    "<wfRunFacts>": [
                        ".*"
                    ]
                }
            },
            "POST/api/v1/orgs/wicked-hop/wfgrps/<wfGrp>/stacks/<stack>/wfs/<wf>/wfruns/<wfRun>/resume/": {
                "name": "ResumeStackWorkflowRun",
                "paths": {
                    "<wfGrp>":var.wfGrp
                    "<stack>": [
                        ".*"
                    ],
                    "<wfRun>": [
                        ".*"
                    ],
                    "<wf>": [
                        ".*"
                    ]
                }
            },
            "PATCH/api/v1/orgs/wicked-hop/wfgrps/<wfGrp>/": {
                "name": "UpdateWorkflowGroup",
                "paths": {
                    "<wfGrp>": var.wfGrp
                }
            },
            "GET/api/v1/orgs/wicked-hop/wfgrps/<wfGrp>/stacks/<stack>/wfs/<wf>/listall_artifacts/": {
                "name": "ListStackWorkflowArtifacts",
                "paths": {
                    "<wfGrp>":var.wfGrp
                    "<stack>": [
                        ".*"
                    ],
                    "<wf>": [
                        ".*"
                    ]
                }
            },
            "POST/api/v1/orgs/wicked-hop/wfgrps/<wfGrp>/wfgrps/": {
                "name": "CreateNestedWorkflowGroup",
                "paths": {
                    "<wfGrp>": var.wfGrp
                }
            },
            "POST/api/v1/orgs/wicked-hop/wfgrps/<wfGrp>/wfs/": {
                "name": "CreateWorkflow",
                "paths": {
                    "<wfGrp>":  var.wfGrp
                }
            },
            "DELETE/api/v1/orgs/wicked-hop/wfgrps/<wfGrp>/wfs/<wf>/wfruns/<wfRun>/": {
                "name": "UpdateWorkflowRun",
                "paths": {
                    "<wfRun>": [
                        ".*"
                    ],
                    "<wfGrp>":var.wfGrp
                    "<wf>": [
                        ".*"
                    ]
                }
            },
            "GET/api/v1/orgs/wicked-hop/wfgrps/<wfGrp>/stacks/<stack>/wfs/<wf>/wfruns/<wfRun>/": {
                "name": "GetStackWorkflowRun",
                "paths": {
                    "<wfGrp>":var.wfGrp
                    "<stack>": [
                        ".*"
                    ],
                    "<wfRun>": [
                        ".*"
                    ],
                    "<wf>": [
                        ".*"
                    ]
                }
            },
            "DELETE/api/v1/orgs/wicked-hop/wfgrps/<wfGrp>/stacks/<stack>/": {
                "name": "DeleteStack",
                "paths": {
                    "<wfGrp>":var.wfGrp
                    "<stack>": [
                        ".*"
                    ]
                }
            },
            "PATCH/api/v1/orgs/wicked-hop/wfgrps/<wfGrp>/wfs/<wf>/": {
                "name": "UpdateWorkflow",
                "paths": {
                    "<wfGrp>":var.wfGrp
                    "<wf>": [
                        ".*"
                    ]
                }
            },
            "POST/api/v1/orgs/wicked-hop/wfgrps/<wfGrp>/stacks/<stack>/stackruns/": {
                "name": "CreateStackRun",
                "paths": {
                    "<wfGrp>":var.wfGrp
                    "<stack>": [
                        ".*"
                    ]
                }
            },
            "GET/api/v1/orgs/wicked-hop/wfgrps/<wfGrp>/wfs/<wf>/listall_artifacts/": {
                "name": "ListWorkflowArtifacts",
                "paths": {
                    "<wfGrp>":var.wfGrp
                    "<wf>": [
                        ".*"
                    ]
                }
            },
            "PATCH/api/v1/orgs/wicked-hop/wfgrps/<wfGrp>/stacks/<stack>/wfs/<wf>/": {
                "name": "UpdateStackWorkflow",
                "paths": {
                    "<wfGrp>":var.wfGrp
                    "<stack>": [
                        ".*"
                    ],
                    "<wf>": [
                        ".*"
                    ]
                }
            },
            "GET/api/v1/orgs/wicked-hop/wfgrps/<wfGrp>/stacks/<stack>/wfs/<wf>/wfruns/<wfRun>/wfrunfacts/<wfRunFacts>/": {
                "name": "GetStackWorkflowRunFact",
                "paths": {
                    "<wfGrp>":var.wfGrp
                    "<stack>": [
                        ".*"
                    ],
                    "<wfRun>": [
                        ".*"
                    ],
                    "<wf>": [
                        ".*"
                    ],
                    "<wfRunFacts>": [
                        ".*"
                    ]
                }
            },
            "GET/api/v1/orgs/wicked-hop/wfgrps/<wfGrp>/stacks/<stack>/wfs/<wf>/outputs/": {
                "name": "GetStackWorkflowOutputs",
                "paths": {
                    "<wfGrp>":var.wfGrp
                    "<stack>": [
                        ".*"
                    ],
                    "<wf>": [
                        ".*"
                    ]
                }
            },
            "GET/api/v1/orgs/wicked-hop/wfgrps/<wfGrp>/stacks/<stack>/wfs/<wf>/wfruns/<wfRun>/logs/": {
                "name": "GetStackWorkflowRunLogs",
                "paths": {
                    "<wfGrp>":var.wfGrp
                    "<stack>": [
                        ".*"
                    ],
                    "<wfRun>": [
                        ".*"
                    ],
                    "<wf>": [
                        ".*"
                    ]
                }
            },
            "POST/api/v1/orgs/wicked-hop/wfgrps/<wfGrp>/wfs/<wf>/wfruns/<wfRun>/resume/": {
                "name": "ResumeWorkflowRun",
                "paths": {
                    "<wfRun>": [
                        ".*"
                    ],
                    "<wfGrp>":var.wfGrp
                    "<wf>": [
                        ".*"
                    ]
                }
            },
            "POST/api/v1/orgs/wicked-hop/wfgrps/<wfGrp>/wfs/<wf>/wfruns/": {
                "name": "CreateWorkflowRun",
                "paths": {
                    "<wfGrp>":var.wfGrp
                    "<wf>": [
                        ".*"
                    ]
                }
            },
            "DELETE/api/v1/orgs/wicked-hop/wfgrps/<wfGrp>/stacks/<stack>/wfs/<wf>/": {
                "name": "DeleteStackWorkflow",
                "paths": {
                    "<wfGrp>":var.wfGrp
                    "<stack>": [
                        ".*"
                    ],
                    "<wf>": [
                        ".*"
                    ]
                }
            },
            "GET/api/v1/orgs/wicked-hop/wfgrps/<wfGrp>/stacks/<stack>/wfs/<wf>/": {
                "name": "GetStackWorkflow",
                "paths": {
                    "<wfGrp>":var.wfGrp
                    "<stack>": [
                        ".*"
                    ],
                    "<wf>": [
                        ".*"
                    ]
                }
            },
            "GET/api/v1/orgs/wicked-hop/wfgrps/<wfGrp>/stacks/<stack>/": {
                "name": "GetStack",
                "paths": {
                    "<wfGrp>":var.wfGrp
                    "<stack>": [
                        ".*"
                    ]
                }
            },
            "GET/api/v1/orgs/wicked-hop/wfgrps/<wfGrp>/wfs/<wf>/": {
                "name": "GetWorkflow",
                "paths": {
                    "<wfGrp>":var.wfGrp
                    "<wf>": [
                        ".*"
                    ]
                }
            },
            "GET/api/v1/orgs/wicked-hop/wfgrps/<wfGrp>/": {
                "name": "GetWorkflowGroup",
                "paths": {
                    "<wfGrp>": var.wfGrp
                }
            },
            "POST/api/v1/orgs/wicked-hop/wfgrps/<wfGrp>/stacks/": {
                "name": "CreateStack",
                "paths": {
                    "<wfGrp>": var.wfGrp
                }
            },
            "GET/api/v1/orgs/wicked-hop/wfgrps/<wfGrp>/wfs/<wf>/outputs/": {
                "name": "GetWorkflowOutputs",
                "paths": {
                    "<wfGrp>":var.wfGrp
                    "<wf>": [
                        ".*"
                    ]
                }
            },
            "DELETE/api/v1/orgs/wicked-hop/wfgrps/<wfGrp>/wfs/<wf>/": {
                "name": "DeleteWorkflow",
                "paths": {
                    "<wfGrp>":var.wfGrp
                    "<wf>": [
                        ".*"
                    ]
                }
            },
            "GET/api/v1/orgs/wicked-hop/wfgrps/<wfGrp>/wfs/<wf>/wfruns/<wfRun>/": {
                "name": "GetWorkflowRun",
                "paths": {
                    "<wfRun>": [
                        ".*"
                    ],
                    "<wfGrp>":var.wfGrp
                    "<wf>": [
                        ".*"
                    ]
                }
            },
            "GET/api/v1/orgs/wicked-hop/wfgrps/<wfGrp>/wfs/<wf>/wfruns/<wfRun>/logs/": {
                "name": "GetWorkflowRunLogs",
                "paths": {
                    "<wfRun>": [
                        ".*"
                    ],
                    "<wfGrp>":var.wfGrp
                    "<wf>": [
                        ".*"
                    ]
                }
            }
        
    }
        
        }
        )
}
}
