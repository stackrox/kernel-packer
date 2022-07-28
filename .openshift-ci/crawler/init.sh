#!/usr/bin/env bash

set -e

# These commands will be executed on a freshly instantiated GCP VM to prepare
# it for the following crawling and repackaging. The main purpose here is to
# set up all the necessary variables needed on the next steps.

export BASH_ENV=/tmp/bash_env

# Cleanup previous state if exists
rm -f "$BASH_ENV"
rm -rf kernel-packer

touch $BASH_ENV

cat >>"$BASH_ENV" <<EOF
export BUILD_ID="${BUILD_ID}"
export BRANCH="${BRANCH}"
export SHARED_DIR="${SHARED_DIR}"
EOF

# Install dependencies
DEBIAN_FRONTEND=noninteractive \
    sudo apt update -y &&\
    sudo apt install -y docker.io make golang jq

# Relogin will require to use this
sudo usermod -aG docker $(whoami)

git clone https://github.com/stackrox/kernel-packer/ \
    --single-branch \
    --branch="${BRANCH}" \
    --depth=1

echo "Initialization is finished!"
