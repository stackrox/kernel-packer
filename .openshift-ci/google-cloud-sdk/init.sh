#!/usr/bin/env bash
set -eo pipefail

which gcloud
echo "Updating gcloud/gsutil ..."

export CLOUDSDK_CONFIG=${HOME}/gcloudconfig
gcloud config set core/disable_prompts True
gcloud components install gsutil -q
gcloud components update -q
gcloud auth activate-service-account --key-file <(echo "$GOOGLE_CREDENTIALS_KERNEL_CACHE")
gcloud auth list

# Sanity check
echo "Using gsutil from $(which gsutil)"
echo "Checking that gsutil binary is functional"
gsutil ls 'gs://stackrox-kernel-packages/' >/dev/null
