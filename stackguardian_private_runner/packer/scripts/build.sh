#!/bin/sh
#
# Shared Packer build driver for the AWS and Azure image builds.
# Both aws/packer/main.tf and azure/packer/main.tf run this file with
# working_dir set to their own module directory.
#
# Inputs (environment):
#   PACKER_VERSION   version of Packer to download
#   PACKER_TEMPLATE  template to init and build, relative to the module dir
#   PKR_VAR_*        every Packer input variable; Packer reads these natively,
#                    so this script never has to know the per-cloud var list

set -e

trap _cleanup EXIT INT TERM

PACKER_EXECUTABLE=""
WORKING_DIR=""
TEMP_DIRS=""

_cleanup() { #{{{
  echo "## ----------"
  echo "Cleaning up Packer build.."

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

_download_packer() { #{{{
  version="$PACKER_VERSION"
  root_dir="$(pwd)"

  os_arch="$(_detect_arch)"
  os_type="$(_detect_os)"
  zip_name="packer_${version}_${os_type}_${os_arch}.zip"
  base_url="https://releases.hashicorp.com/packer/${version}"

  download_url="${base_url}/${zip_name}"

  echo "## ----------"
  echo ">> Downloading Packer v${version}.."
  _mktemp_directory && cd "$WORKING_DIR"

  if _wget_wrapper "$download_url"; then
    unzip "$zip_name"
    PACKER_EXECUTABLE="$(realpath packer)"
    cd "$root_dir"

    echo ">> Downloaded to ${PACKER_EXECUTABLE}."
    echo "## ----------"
  else
    echo "ERROR: Failed to download from: $download_url"
    exit 1
  fi
}
#}}}: _download_packer

main() { #{{{
  if [ -z "$PACKER_TEMPLATE" ]; then
    echo "ERROR: PACKER_TEMPLATE is not set."
    exit 1
  fi

  _download_packer

  $PACKER_EXECUTABLE init "$PACKER_TEMPLATE"
  $PACKER_EXECUTABLE build \
    -machine-readable \
    "$PACKER_TEMPLATE" | tee packer_manifest.log

  # tee masks Packer's exit status, so check for the artifact line instead.
  # Terraform records the build as done as soon as this script succeeds, so a
  # silent failure here would stick until the rebuild token is changed.
  if ! grep -q 'artifact,0,id' packer_manifest.log; then
    echo "ERROR: Packer build produced no image. See the output above."
    exit 1
  fi
}
#}}}: main

main "$@"
