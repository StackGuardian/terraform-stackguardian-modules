#!/bin/sh

set -e

trap _cleanup EXIT INT TERM

OS_ARCH=""
OS_TYPE=""

WORKING_DIR=""
TEMP_DIRS=""

_cleanup() { #{{{
  echo "## ----------"
  echo ">> Cleaning up AMI setup.."

  if [ -n "$TEMP_DIRS" ]; then
    for temp_dir in $TEMP_DIRS; do
      if [ -d "$temp_dir" ]; then
        rm -rf "$temp_dir"
        echo "Removed temporary directory: $temp_dir"
      fi
    done
  fi

  if [ -d "$WORKING_DIR" ]; then
    rm -rf "$WORKING_DIR"
    echo "Removed temporary directory: $WORKING_DIR"
  fi
  echo "## ----------"
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
    echo ">> Enabling $service.."
    sudo systemctl enable --now "$service"
  done
}
#}}}: _systemctl_enable

_usermod_add_to_group() { #{{{
  group="$1"
  user="$2"

  echo ">> Adding ${user} to the ${group} group.."
  sudo usermod -aG "$group" "$user" || true
}
#}}}: _usermod_add_to_group

_wget_wrapper() { #{{{
  url="$1"
  output_file="${2:-"${url##*/}"}"

  echo ">> Downloading ${url}.."
  wget -q "$url" -O "$output_file"
  echo ">> Saved to ${output_file}."
}
#}}}: _wget_wrapper

_mktemp_directory() { #{{{
  WORKING_DIR="$(mktemp -d)"
  if [ -n "$TEMP_DIRS" ]; then
    TEMP_DIRS="$TEMP_DIRS $WORKING_DIR"
  else
    TEMP_DIRS="$WORKING_DIR"
  fi
}
#}}}: _mktemp_directory

_detect_arch() { #{{{
  machine="$(uname -m)"

  case "$machine" in
    x86_64) echo "amd64" ;;
    aarch64) echo "arm64" ;;
    armv7l) echo "arm" ;;
    i386|i686) echo "386" ;;
    *) echo "$machine" ;;
  esac
}
#}}}: _detect_arch

_detect_os() { #{{{
    uname -s | tr '[:upper:]' '[:lower:]'
}
#}}}: _detect_os

_install_terraform() { #{{{
  version="${1:-$TERRAFORM_VERSION}"
  target_name="terraform"

  if [ -n "$1" ]; then
    target_name="terraform$version"
  fi

  # os_arch="$(_detect_arch)"
  # os_type="$(_detect_os)"
  os_arch="$OS_ARCH"
  os_type="$OS_TYPE"
  zip_name="terraform_${version}_${os_type}_${os_arch}.zip"
  base_url="https://releases.hashicorp.com/terraform/${version}"

  download_url="${base_url}/${zip_name}"

  echo "## ----------"
  echo ">> Installing Terraform v${version}.."
  _mktemp_directory && cd "$WORKING_DIR"

  if _wget_wrapper "$download_url"; then
    unzip "$zip_name"
    sudo mv terraform "/usr/bin/$target_name"

    echo ">> Installed to $(which "$target_name")."
    echo "## ----------"
  else
    echo "ERROR: Failed to download Terraform v$version from: $download_url"
    exit 1
  fi
}
#}}}: _install_terraform

_install_terraform_versions() { #{{{
  versions_list="$TERRAFORM_VERSIONS"

  for version in $versions_list; do
    _install_terraform "$version"
  done
}
#}}}: _install_terraform_versions

_install_opentofu() { #{{{
  version="${1:-$OPENTOFU_VERSION}"
  target_name="tofu"

  if [ -n "$1" ]; then
    target_name="tofu$version"
  fi

  # os_arch="$(_detect_arch)"
  # os_type="$(_detect_os)"
  os_arch="$OS_ARCH"
  os_type="$OS_TYPE"
  zip_name="tofu_${version}_${os_type}_${os_arch}.zip"
  base_url="https://github.com/opentofu/opentofu/releases/download/v$version"

  download_url="${base_url}/${zip_name}"

  echo "## ----------"
  echo ">> Installing OpenTofu v${version}.."
  _mktemp_directory && cd "$WORKING_DIR"

  if _wget_wrapper "$download_url"; then
    unzip "$zip_name"
    sudo mv tofu "/usr/bin/$target_name"

    echo ">> Installed to $(which "$target_name")."
    echo "## ----------"
  else
    echo "ERROR: Failed to download OpenTofu v$version from: $download_url"
    exit 1
  fi
}
#}}}: _install_opentofu

_install_opentofu_versions() { #{{{
  versions_list="$OPENTOFU_VERSIONS"

  for version in $versions_list; do
    _install_opentofu "$version"
  done
}
#}}}: _install_opentofu_versions

_install_sg_runner() { #{{{
  url="$(wget -qO- "https://api.github.com/repos/stackguardian/sg-runner/releases/latest" | jq -r '.tarball_url')"
  runner_archive="runner.tar.gz"

  echo "## ----------"
  echo ">> Installing sg-runner.."

  _mktemp_directory && cd "$WORKING_DIR"

  if _wget_wrapper "$url" "$runner_archive"; then
    tar -xf "$runner_archive"
    sudo cp -rf StackGuardian-sg-runner*/main.sh /usr/bin/sg-runner

    echo ">> Installed to $(which sg-runner)."
    echo "## ----------"
  else
    echo "ERROR: Failed to download from: $url"
    exit 1
  fi
}
#}}}: _install_sg_runner

_user_script_wrapper() { #{{{
  script="$USER_SCRIPT"

  if [ -n "$script" ]; then
    echo ">> Preparing user environment.."
    _mktemp_directory && cd "$WORKING_DIR"

    if ! sh -c "$script"; then
      echo "ERROR: Script execution failed."
      exit 1
    fi

    echo ">> User script completed successfully!"
  fi
}
#}}}: _user_script_wrapper

main() { #{{{
  if [ "$OS_FAMILY" = "ubuntu" ]; then
    _apt_dependencies
    _systemctl_enable "cron"
    _usermod_add_to_group "docker" "ubuntu"
  else
    _yum_dependencies
    _systemctl_enable "crond" "amazon-ssm-agent"
    _usermod_add_to_group "docker" "ec2-user"
  fi
  _systemctl_enable "docker"

  OS_ARCH="$(_detect_arch)"
  OS_TYPE="$(_detect_os)"

  _install_terraform
  _install_terraform_versions

  _install_opentofu
  _install_opentofu_versions

  _install_sg_runner

  _user_script_wrapper
}
#}}}: main

main "$@"
