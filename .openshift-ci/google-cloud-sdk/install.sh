#!/usr/bin/env bash
set -eo pipefail

# Inspired by the implementation from CircleCI gcp-cli-orb
# https://github.com/CircleCI-Public/gcp-cli-orb

GOOGLE_CLOUD_SDK_VERSION=383.0.0

install () {
  # Set sudo to work whether logged in as root user or non-root user
  if [[ $EUID == 0 ]]; then export SUDO=""; else export SUDO="sudo"; fi
  curl -Ss --retry 5 https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-"${GOOGLE_CLOUD_SDK_VERSION}"-linux-x86_64.tar.gz | tar xz
  source ~/google-cloud-sdk/path.bash.inc
}

if [[ $(command -v gcloud) == "" ]]; then
    install
else
    echo "gcloud CLI is already installed."
fi
