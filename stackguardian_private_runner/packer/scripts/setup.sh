#!/usr/bin/env bash

set -eo pipefail

trap _cleanup EXIT SIGINT SIGTERM ERR

declare WORKING_DIR
declare -a TEMP_DIRS

_cleanup() { #{{{
  echo "Cleaning up.."

  for temp_dir in "${TEMP_DIRS[@]}"; do
    if [[ -d "$temp_dir" ]]; then
      rm -rf "$temp_dir"
      echo "Removed temporary directory: $temp_dir"
    fi
  done

  if [[ -d "$WORKING_DIR" ]]; then
    rm -rf "$WORKING_DIR"
    echo "Removed temporary directory: $WORKING_DIR"
  fi
}
#}}}: _cleanup

_apt_dependencies() { #{{{
  sudo apt update
  sudo apt install -y \
    docker.io \
    jq \
    cron \
    wget
}
#}}}: _apt_dependencies

_yum_dependencies() { #{{{
  sudo yum update
  sudo yum install -y \
    docker \
    jq \
    cronie \
    gnupg2 \
    wget
}
#}}}: _yum_dependencies

_systemctl_enable() { #{{{
  for service in "$@"; do
    echo "Enabling $service.."
    sudo systemctl enable --now "$service"
  done
}
#}}}: _systemctl_enable

_usermod_add_to_group() { #{{{
  local group="$1"
  local user="$2"

  echo "Adding ${user} to the ${group} group.."
  sudo usermod -aG "$group" "$user" || true
}
#}}}: _usermod_add_to_group

_wget_wrapper() { #{{{
  local url="$1"
  local output_file="${2:-"${url##*/}"}"

  echo "Downloading ${url}.."
  wget -q "$url" -O "$output_file"
  echo "Saved to ${output_file}."
}
#}}}: _wget_wrapper

_mktemp_directory() { #{{{
  # local -n ref="$1"
  # ref="$(mktemp -d)"

  WORKING_DIR="$(mktemp -d)"
  TEMP_DIRS+=("$WORKING_DIR")
}
#}}}: _mktemp_directory

_detect_arch() { #{{{
  local machine="$(uname -m)"

  declare -A arch_map=(
    ["x86_64"]="amd64"
    ["aarch64"]="arm64"
    ["armv7l"]="arm"
    ["i386"]="386"
    ["i686"]="386"
  )

  echo "${arch_map[$machine]:-$machine}"
}
#}}}: _detect_arch

_detect_os() { #{{{
    uname -s | tr '[:upper:]' '[:lower:]'
}
#}}}: _detect_os

_install_terraform() { #{{{
  local version="$TERRAFORM_VERSION"

  local os_arch="$(_detect_arch)"
  local os_type="$(_detect_os)"
  local zip_name="terraform_${version}_${os_type}_${os_arch}.zip"
  local base_url="https://releases.hashicorp.com/terraform/${version}"

  local download_url="${base_url}/${zip_name}"

  echo "Installing Terraform v${version}.."
  _mktemp_directory && cd "$WORKING_DIR"

  if _wget_wrapper "$download_url"; then
    unzip "$zip_name"
    sudo mv terraform /usr/bin/

    echo "Installed to $(which terraform)."
  else
    echo "Failed to download from: $download_url"
    exit 1
  fi
}
#}}}: _install_terraform

_install_sg_runner() { #{{{
  local url="$(wget -qO- "https://api.github.com/repos/stackguardian/sg-runner/releases/latest" | jq -r '.tarball_url')"
  local runner_archive="runner.tar.gz"

  echo "Installing sg-runner.."

  _mktemp_directory && cd "$WORKING_DIR"

  if _wget_wrapper "$url" "$runner_archive"; then
    tar -xf "$runner_archive"
    sudo cp -rf StackGuardian-sg-runner*/main.sh /usr/bin/sg-runner

    echo "Installed to $(which sg-runner)."
  else
    echo "Failed to download from: $url"
    exit 1
  fi
}
#}}}: _install_sg_runner

_user_script_wrapper() { #{{{
  local script="$USER_SCRIPT"

  if [[ -n "$script" ]]; then
    echo "Preparing user environment.."
    _mktemp_directory && cd "$WORKING_DIR"

    if ! bash -c "$script"; then
      echo "Script execution failed."
      exit 1
    fi

    echo "User script completed successfully!"
  fi
}
#}}}: _user_script_wrapper

main() { #{{{
  if [[ "$OS_FAMILY" == "ubuntu" ]]; then
    _apt_dependencies
    _systemctl_enable "cron"
    _usermod_add_to_group "docker" "ubuntu"
  else
    _yum_dependencies
    _systemctl_enable "crond" "amazon-ssm-agent"
    _usermod_add_to_group "docker" "ec2-user"
  fi
  _systemctl_enable "docker"

  _install_terraform
  _install_sg_runner
  _user_script_wrapper
}
#}}}: main

main "$@"
