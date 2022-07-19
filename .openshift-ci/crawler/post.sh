#!/usr/bin/env bash
set -eo pipefail

# This script will be executed after crawling and repackaging and serves as a
# resources tear down phase.

source .openshift-ci/env.sh
source .openshift-ci/google-cloud-sdk/install.sh
source .openshift-ci/google-cloud-sdk/init.sh

.openshift-ci/gcp/delete-vm.sh
