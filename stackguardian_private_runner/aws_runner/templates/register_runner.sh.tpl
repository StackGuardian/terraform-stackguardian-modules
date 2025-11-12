#!/usr/bin/env sh

set -e

startup_log_file="/var/log/sg_runner_startup.log"

## Sometimes registration fails because `docker.service` is not ready.
## We will check if `docker.service` is ready and continue.
## Otherwise, sleep for 1 second and try again.
## Wait for Docker with same timeout as autoscaler scale_out_cooldown.
## If not provided, by default set to 5 minutes max
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

## Register Private Runner
export SG_BASE_API="${sg_api_uri}/api/v1"
sg-runner register \
  --organization "${sg_org_name}" \
  --runner-group "${sg_runner_group_name}" \
  --sg-node-token "${sg_runner_group_token}" 2>&1 | tee -a "$startup_log_file"
