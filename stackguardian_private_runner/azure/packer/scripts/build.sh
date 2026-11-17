#!/bin/sh
# Resolves Azure credentials, then runs the shared Packer build script.
# Run from the module directory (local-exec working_dir = path.module).

set -e

. ./scripts/azure_auth.sh

exec sh ../../packer/scripts/build.sh
