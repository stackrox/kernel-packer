#!/usr/bin/env bash
set -eo pipefail

# Assume we need to run in staging mode unconditionally for testing purposes.

# The below variables ontain a comma delimited list of GCP buckets,
# Scripts may read from all buckets but only write to the first bucket in the list.
KERNEL_PACKAGE_STAGING_BUCKET="gs://stackrox-kernel-packages-test/${CIRCLE_BRANCH}/${CIRCLE_SHA1}"
KERNEL_BUNDLE_STAGING_BUCKET="gs://stackrox-kernel-bundles-test/${CIRCLE_BRANCH}/${CIRCLE_SHA1}"
KERNEL_PACKAGE_BUCKET="${KERNEL_PACKAGE_STAGING_BUCKET}"
KERNEL_BUNDLE_BUCKET="${KERNEL_BUNDLE_STAGING_BUCKET}"

echo "KERNEL_BUNDLE_STAGING_BUCKET=${KERNEL_BUNDLE_STAGING_BUCKET}"
echo "KERNEL_PACKAGE_STAGING_BUCKET=${KERNEL_PACKAGE_STAGING_BUCKET}"
echo "KERNEL_BUNDLE_BUCKET=${KERNEL_BUNDLE_BUCKET}"
echo "KERNEL_PACKAGE_BUCKET=${KERNEL_PACKAGE_BUCKET}"

export KERNEL_PACKAGE_STAGING_BUCKET="${KERNEL_PACKAGE_STAGING_BUCKET}"
export KERNEL_BUNDLE_STAGING_BUCKET="${KERNEL_BUNDLE_STAGING_BUCKET}"
export KERNEL_PACKAGE_BUCKET="${KERNEL_PACKAGE_BUCKET}"
export KERNEL_BUNDLE_BUCKET="${KERNEL_BUNDLE_BUCKET}"

source .openshift-ci/env.sh
source .openshift-ci/google-cloud-sdk/install.sh
source .openshift-ci/google-cloud-sdk/init.sh

if ! make -j -k crawl-centos-no-docker 2> >(tee /tmp/make-crawl-stderr >&2) ; then
    touch /tmp/crawl-failed
fi

#./scripts/restore-removed

make sync
