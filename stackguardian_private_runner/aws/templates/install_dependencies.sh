#!/bin/bash
set -e

# Install Docker, crontab, jq
if [[ "$OS_FAMILY" == "ubuntu" ]]; then
  ## Ubuntu Dependencies
  sudo apt update
  sudo apt install -y docker.io jq cron

  sudo systemctl enable --now cron
  sudo usermod -aG docker ubuntu || true
else
  ## RHEL, Amazon Linux Dependencies
  sudo yum update -y
  sudo yum install -y docker jq cronie gnupg2 wget curl git amazon-ssm-agent

  sudo systemctl enable --now crond
  sudo systemctl enable --now amazon-ssm-agent
  sudo usermod -aG docker ec2-user || true
fi


## Enable and start Docker and cron services
sudo systemctl enable --now docker
