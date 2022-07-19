#!/usr/bin/env bash
set -eo pipefail

# GCloud SDK initialization script could be invoked from two environment, Prow
# or a GCP VM.

which gcloud || true
echo "Updating gcloud/gsutil ..."

export CLOUDSDK_CONFIG=/tmp/gcloudconfig

# Do not bother showing prompt e.g. for confirming deleting a VM
gcloud config set core/disable_prompts True

# If it happens on a GCP VM, gcloud is already there and don't have to be
# updated manually (only via package manager)
gcloud components install gsutil -q || true
gcloud components update -q &>> /dev/null || true
gcloud config set project stackrox-ci

gcloud auth activate-service-account --key-file <(echo "$GOOGLE_CREDENTIALS_KERNEL_CACHE")
gcloud auth list

# Originally envbuilder was iterating through available zones, as some of the
# VM images could not be available in certain zones. It's not needed anymore,
# so we can pin one particular zone.
gcloud config set compute/zone us-central1-a

# Sanity check
echo "Using gsutil from $(which gsutil)"
echo "Checking that gsutil binary is functional"
gsutil ls 'gs://stackrox-kernel-packages-staging/' >/dev/null
