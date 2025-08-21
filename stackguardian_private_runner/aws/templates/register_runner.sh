#!/usr/bin/env sh

set -e

## Register Private Runner
export SG_BASE_API="https://api.app.stackguardian.io/api/v1"
sg-runner register \
  --organization "${sg_org_name}" \
  --runner-group "${sg_runner_group_name}" \
  --sg-node-token "${sg_runner_group_token}"
