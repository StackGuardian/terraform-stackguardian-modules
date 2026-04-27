#!/bin/sh

set -e

trap _cleanup EXIT INT TERM

OS_ARCH=""
OS_TYPE=""

WORKING_DIR=""
TEMP_DIRS=""

# Configure proxy settings if provided.
# Sets shell + wget proxy globally; package-manager proxy is configured
# inside the per-OS dependency function so the file lands in the right place.
_configure_proxy() { #{{{
  if [ -n "$PROXY_URL" ]; then
    echo ">> Configuring proxy: $PROXY_URL"
    export http_proxy="$PROXY_URL"
    export https_proxy="$PROXY_URL"
    export HTTP_PROXY="$PROXY_URL"
    export HTTPS_PROXY="$PROXY_URL"

    {
      echo "http_proxy = $PROXY_URL"
      echo "https_proxy = $PROXY_URL"
      echo "use_proxy = on"
    } >> ~/.wgetrc
  fi
}
#}}}: _configure_proxy

_cleanup() { #{{{
  echo "## ----------"
  echo ">> Cleaning up image setup.."

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
}
#}}}: _cleanup

_wait_for_cloud_init() { #{{{
  echo ">> Waiting for cloud-init to complete.."
  if command -v cloud-init >/dev/null 2>&1; then
    sudo cloud-init status --wait || true
  fi
  echo ">> Cloud-init completed."
}
#}}}: _wait_for_cloud_init

_apt_dependencies() { #{{{
  _wait_for_cloud_init

  # Wait for apt locks to be released
  echo ">> Waiting for apt locks.."
  while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || \
        sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
    echo ">> Waiting for apt lock to be released.."
    sleep 5
  done

  if [ "$UPDATE_OS" = "true" ]; then
    if [ -n "$PROXY_URL" ]; then
      echo "Acquire::http::Proxy \"$PROXY_URL\";" | sudo tee /etc/apt/apt.conf.d/01proxy
      echo "Acquire::https::Proxy \"$PROXY_URL\";" | sudo tee -a /etc/apt/apt.conf.d/01proxy
    fi
    sudo apt-get update
  fi
  sudo apt-get install -y \
    docker.io \
    unzip \
    cron \
    wget
}
#}}}: _apt_dependencies

_dnf_dependencies() { #{{{
  if [ "$UPDATE_OS" = "true" ]; then
    if [ -n "$PROXY_URL" ]; then
      echo "proxy=$PROXY_URL" | sudo tee -a /etc/dnf/dnf.conf
    fi
    sudo dnf update -y
  fi
  sudo dnf install -y \
    dnf-plugins-core \
    unzip \
    cronie \
    wget

  sudo dnf config-manager \
    --add-repo "https://download.docker.com/linux/rhel/docker-ce.repo"
  sudo dnf install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io
}
#}}}: _dnf_dependencies

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

_get_latest_github_release() { #{{{
  repo="$1"
  file_name="$2"
  latest_release_url="https://api.github.com/repos/$repo/releases/latest"

  wget -qO- "$latest_release_url" \
    | grep "\"browser_download_url\": \".*/$file_name\"" \
    | tr -d ' "' \
    | grep -o 'https.*'
}
#}}}: _get_latest_github_release

_install_jq() { #{{{
  os_arch="$OS_ARCH"
  os_type="$OS_TYPE"
  file_name="jq-${os_type}-${os_arch}"

  echo "## ----------"
  echo ">> Fetching latest jq version.."
  download_url="$(_get_latest_github_release "jqlang/jq" "$file_name")"

  if [ -z "$download_url" ]; then
    echo "ERROR: Failed to fetch latest jq version"
    exit 1
  fi

  echo ">> Installing jq.."
  _mktemp_directory && cd "$WORKING_DIR"

  if _wget_wrapper "$download_url"; then
    sudo chmod +x "$file_name"
    sudo mv "$file_name" "/usr/bin/jq"

    echo ">> Installed to $(which jq)."
    echo ">> Version: $(jq --version)"
  else
    echo "ERROR: Failed to download jq from: $download_url"
    exit 1
  fi
}
#}}}: _install_jq

_install_terraform() { #{{{
  if [ -z "$TERRAFORM_VERSION" ]; then
    return
  fi

  version="${1:-$TERRAFORM_VERSION}"
  target_name="terraform"

  if [ -n "$1" ]; then
    target_name="terraform$version"
  fi

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
  if [ -z "$OPENTOFU_VERSION" ]; then
    return
  fi

  version="${1:-$OPENTOFU_VERSION}"
  target_name="tofu"

  if [ -n "$1" ]; then
    target_name="tofu$version"
  fi

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
  runner_archive="runner.tar.gz"
  github_api_base="https://api.github.com/repos/stackguardian/sg-runner"

  echo "## ----------"
  echo ">> Installing sg-runner.."

  if [ "$SG_RUNNER_PRE_RELEASE" = "true" ]; then
    echo ">> Fetching latest pre-release.."
    url="$(wget -qO- "${github_api_base}/releases" | jq -r '[.[] | select(.prerelease == true)][0].tarball_url // empty')"
    if [ -z "$url" ]; then
      echo ">> No pre-release found, falling back to latest stable.."
      url="$(wget -qO- "${github_api_base}/releases/latest" | jq -r '.tarball_url')"
    fi
  else
    echo ">> Fetching latest stable release.."
    url="$(wget -qO- "${github_api_base}/releases/latest" | jq -r '.tarball_url')"
  fi

  if [ -z "$url" ]; then
    echo "ERROR: Failed to fetch sg-runner release URL"
    exit 1
  fi

  _mktemp_directory && cd "$WORKING_DIR"

  if _wget_wrapper "$url" "$runner_archive"; then
    tar -xf "$runner_archive"
    sudo cp -rf StackGuardian-sg-runner*/main.sh /usr/bin/sg-runner

    echo ">> Installed to $(which sg-runner)."
  else
    echo "ERROR: Failed to download from: $url"
    exit 1
  fi

  # Persist runtime config consumed by /usr/bin/sg-runner-update
  echo "# StackGuardian Runner configuration" | sudo tee /etc/sg-runner.conf > /dev/null
  echo "SG_RUNNER_PRE_RELEASE=${SG_RUNNER_PRE_RELEASE:-false}" | sudo tee -a /etc/sg-runner.conf > /dev/null
  echo ">> Saved config to /etc/sg-runner.conf"
}
#}}}: _install_sg_runner

_install_sg_runner_update() { #{{{
  echo "## ----------"
  echo ">> Installing sg-runner-update script.."

  sudo tee /usr/bin/sg-runner-update > /dev/null << 'SCRIPT_EOF'
#!/bin/sh
set -e

GITHUB_API_BASE="https://api.github.com/repos/stackguardian/sg-runner"
CONFIG_FILE="/etc/sg-runner.conf"

SG_RUNNER_PRE_RELEASE="false"
if [ -f "$CONFIG_FILE" ]; then
  . "$CONFIG_FILE"
fi

if [ -n "$1" ]; then
  echo ">> Downloading sg-runner ref: $1"
  url="${GITHUB_API_BASE}/tarball/$1"
else
  if [ "$SG_RUNNER_PRE_RELEASE" = "true" ]; then
    echo ">> Fetching latest pre-release.."
    url="$(wget -qO- "${GITHUB_API_BASE}/releases" | jq -r '[.[] | select(.prerelease == true)][0].tarball_url // empty')"
    if [ -z "$url" ]; then
      echo ">> No pre-release found, falling back to latest stable.."
      url="$(wget -qO- "${GITHUB_API_BASE}/releases/latest" | jq -r '.tarball_url')"
    fi
  else
    echo ">> Fetching latest stable release.."
    url="$(wget -qO- "${GITHUB_API_BASE}/releases/latest" | jq -r '.tarball_url')"
  fi
fi

if [ -z "$url" ]; then
  echo "ERROR: Failed to determine download URL"
  exit 1
fi

TEMP_DIR="$(mktemp -d)"
trap "rm -rf '$TEMP_DIR'" EXIT

cd "$TEMP_DIR"
echo ">> Downloading from: $url"
wget -q "$url" -O runner.tar.gz

tar -xf runner.tar.gz
sudo cp -rf StackGuardian-sg-runner*/main.sh /usr/bin/sg-runner

echo ">> sg-runner updated successfully!"
echo ">> Installed to: $(which sg-runner)"
SCRIPT_EOF

  sudo chmod +x /usr/bin/sg-runner-update
  echo ">> Installed sg-runner-update to /usr/bin/sg-runner-update"
}
#}}}: _install_sg_runner_update

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

_handle_os_package_installation() { #{{{
  if [ "$OS_FAMILY" = "ubuntu" ]; then
    _apt_dependencies
    _systemctl_enable "cron" "docker"
    _usermod_add_to_group "docker" "ubuntu"
  elif [ "$OS_FAMILY" = "rhel" ]; then
    _dnf_dependencies
    _systemctl_enable "crond" "docker"
    _usermod_add_to_group "docker" "azureuser"
  else
    echo "ERROR: Unsupported OS_FAMILY: $OS_FAMILY"
    exit 1
  fi

}
#}}}: _handle_os_package_installation

main() { #{{{
  OS_ARCH="$(_detect_arch)"
  OS_TYPE="$(_detect_os)"

  _configure_proxy

  _handle_os_package_installation

  _install_jq

  _install_terraform
  _install_terraform_versions

  _install_opentofu
  _install_opentofu_versions

  _install_sg_runner
  _install_sg_runner_update

  _user_script_wrapper
}
#}}}: main

main "$@"
