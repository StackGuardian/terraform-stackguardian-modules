#!/usr/bin/env bash

readonly OS_ARCH="$(uname -m)"
readonly OS_TYPE="$(uname -o)"
readonly PACKER_ZIP_NAME="packer_${PACKER_VERSION}_${OS_TYPE,,}_${OS_ARCH}.zip"

wget -q "https://releases.hashicorp.com/packer/${PACKER_VERSION}/${PACKER_ZIP_NAME}"
unzip "$PACKER_ZIP_NAME"

set -o pipefail

./packer init ./ami.pkr.hcl
./packer build \
  -var "os_family=$OS_FAMILY" \
  -var "os_version=$OS_VERSION" \
  -var "ssh_username=$SSH_USERNAME" \
  -var "base_ami=$BASE_AMI" \
  -var "region=$REGION" \
  -var "vpc_id="$VPC_ID \
  -var "subnet_id="$SUBNET_ID \
  -machine-readable \
  ./ami.pkr.hcl | tee packer_manifest.log
