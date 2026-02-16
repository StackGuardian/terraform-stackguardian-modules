#!/usr/bin/env bash

set -e

startup_log_file="/var/log/sg_runner_startup.log"

echo ">> Starting StackGuardian Private Runner registration..." | tee -a "$startup_log_file"

## Wait for Docker with timeout
## Sometimes registration fails because docker.service is not ready.
## We will check if docker.service is ready and continue.
## Otherwise, sleep for 1 second and try again.
timeout="${sg_runner_startup_timeout}"
counter=0

until systemctl is-active --quiet docker; do
  echo ">> Docker not ready.. Trying again in 1 second." | tee -a "$startup_log_file"
  sleep 1
  counter=$((counter + 1))

  if [ $counter -ge $timeout ]; then
    echo ">> ERROR: Docker failed to start after $timeout seconds. Shutting down instance." | tee -a "$startup_log_file"
    shutdown -h now
  fi
done

echo ">> Docker is ready." | tee -a "$startup_log_file"

## Register Private Runner
export SG_BASE_API="${sg_api_uri}/api/v1"
sg-runner register \
  --organization "${sg_org_name}" \
  --runner-group "${sg_runner_group_name}" \
  --sg-node-token "${sg_runner_group_token}" 2>&1 | tee -a "$startup_log_file"

echo ">> StackGuardian Private Runner registration complete." | tee -a "$startup_log_file"
