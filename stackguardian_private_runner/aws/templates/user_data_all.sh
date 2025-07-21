#!/bin/bash
set -e

# Install Docker, crontab, jq
%{ if os_family == "ubuntu" }
## Ubuntu Dependencies
apt update
apt install -y docker.io jq cron

systemctl enable --now cron
usermod -aG docker ubuntu || true
%{ else }
## RHEL, Amazon Linux Dependencies
yum update -y
yum install -y docker jq cronie gnupg2 wget curl git amazon-ssm-agent

systemctl enable --now crond
systemctl enable --now amazon-ssm-agent
usermod -aG docker ec2-user || true
%{ endif }

## Enable and start Docker and cron services
systemctl enable --now docker

## Register Private Runner
DOWNLOAD_URL="$(wget -qO- "https://api.github.com/repos/stackguardian/sg-runner/releases/latest" | jq -r '.tarball_url')"
wget -q "$DOWNLOAD_URL" -O runner.tar.gz && \
  tar -xf runner.tar.gz && \
  cp -rf StackGuardian-sg-runner*/main.sh /usr/bin/sg-runner && \
  rm -rfd StackGuardian-sg-runner* runner.tar.gz

export SG_BASE_API="${sg_api_uri}/api/v1"
sg-runner register \
  --organization "${sg_org_name}" \
  --runner-group "${sg_runner_group_name}" \
  --sg-node-token "${sg_runner_group_token}"
