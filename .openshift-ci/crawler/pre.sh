#!/usr/bin/env bash
set -eo pipefail

# Before doing anything, we need to dump PR data for all upcoming steps
.openshift-ci/scripts/dump-pr-data.sh

# The script will be executed before crawling and repackaging on Prow. It will
# spin up and bootstrap a GCP VM.

source .openshift-ci/env.sh
source .openshift-ci/google-cloud-sdk/install.sh
source .openshift-ci/google-cloud-sdk/init.sh

.openshift-ci/gcp/create-vm.sh
.openshift-ci/crawler/bootstrap-vm.sh
