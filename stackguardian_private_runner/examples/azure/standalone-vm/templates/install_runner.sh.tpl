#!/usr/bin/env bash
#
# Replicates a production StackGuardian private runner host for investigation:
#   - RHEL 9.x
#   - Docker pinned to a specific version (production: 29.5.2 / build 79eb04c)
#   - sg-runner pinned to a specific release tag (production: "Installationsscript v2.2.1")
#
# Mirrors the RHEL path of the Packer image setup
# (azure/packer/scripts/setup.sh) but pins versions instead of installing latest,
# then registers the runner.

set -euo pipefail

LOG=/var/log/sg_runner_startup.log
exec > >(tee -a "$LOG") 2>&1

echo ">> [replica] starting install on: $(cat /etc/redhat-release 2>/dev/null || echo unknown)"

# 1. Base dependencies (matches _dnf_dependencies)
dnf install -y dnf-plugins-core unzip cronie wget

# 2. Docker repo + PINNED engine (production: ${docker_version} / build 79eb04c)
dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
DOCKER_VERSION="${docker_version}"
# RHEL package strings look like "3:29.5.2-1.el9"; match the version with a glob so the
# epoch / dist suffix don't have to be hardcoded.
dnf install -y \
  "docker-ce-*$${DOCKER_VERSION}*" \
  "docker-ce-cli-*$${DOCKER_VERSION}*" \
  containerd.io

# 3. Enable services + docker group (matches _systemctl_enable / _usermod_add_to_group)
systemctl enable --now crond docker
usermod -aG docker ${admin_username} || true

# 4. jq (sg-runner depends on it)
ARCH=amd64
JQ_URL=$(wget -qO- https://api.github.com/repos/jqlang/jq/releases/latest \
  | grep browser_download_url | grep "jq-linux-$${ARCH}" | head -1 | cut -d'"' -f4)
wget -qO /usr/bin/jq "$${JQ_URL}"
chmod +x /usr/bin/jq

# 5. sg-runner PINNED to the production tag (Installationsscript ${sg_runner_version})
TMP=$(mktemp -d)
wget -qO "$${TMP}/runner.tar.gz" \
  "https://api.github.com/repos/stackguardian/sg-runner/tarball/${sg_runner_version}"
tar -xf "$${TMP}/runner.tar.gz" -C "$${TMP}"
cp -rf "$${TMP}"/StackGuardian-sg-runner*/main.sh /usr/bin/sg-runner
chmod +x /usr/bin/sg-runner
rm -rf "$${TMP}"
echo ">> sg-runner installed: $(which sg-runner)"

# 6. Wait for Docker (same guard as the original register_runner.sh.tpl)
timeout="${startup_timeout}"
counter=0
until systemctl is-active --quiet docker; do
  echo ">> Docker not ready.. trying again in 1 second."
  sleep 1
  counter=$((counter + 1))
  if [ $counter -ge $timeout ]; then
    echo ">> ERROR: Docker failed to start after $${timeout} seconds."
    exit 1
  fi
done
echo ">> Docker ready: $(docker --version)"

# 7. Register the private runner
export SG_BASE_API="${sg_api_uri}/api/v1"
sg-runner register \
  --organization "${sg_org_name}" \
  --runner-group "${sg_runner_group_name}" \
  --sg-node-token "${sg_runner_group_token}"

echo ">> StackGuardian Private Runner registration complete."
