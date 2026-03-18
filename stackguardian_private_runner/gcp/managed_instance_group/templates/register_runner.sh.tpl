#!/usr/bin/env sh

set -e

startup_log_file="/var/log/sg_runner_startup.log"

# Set up GCP-to-AWS credential federation for S3 access
echo ">> Setting up AWS credential federation via GCP identity token" | tee -a "$startup_log_file"
GCP_METADATA_URL="http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/identity"
curl -sf -H "Metadata-Flavor: Google" \
  "$${GCP_METADATA_URL}?audience=sts.amazonaws.com&format=full" \
  > /tmp/gcp_identity_token

export AWS_WEB_IDENTITY_TOKEN_FILE=/tmp/gcp_identity_token
export AWS_ROLE_ARN="${aws_role_arn}"

# Persist for sg-runner process
echo "AWS_WEB_IDENTITY_TOKEN_FILE=/tmp/gcp_identity_token" | sudo tee -a /etc/environment
echo "AWS_ROLE_ARN=${aws_role_arn}" | sudo tee -a /etc/environment

# Start token refresh timer if available
if systemctl list-unit-files | grep -q gcp-aws-token-refresh.timer; then
  sudo systemctl start gcp-aws-token-refresh.timer
fi

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
