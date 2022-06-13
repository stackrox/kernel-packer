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

# temporary clean-up package list to reduce crawling time
shopt -s extglob
rm kernel-package-lists/!(centos.txt|centos-uncrawled.txt|reformat.yml)
cat <<EOT > kernel-package-lists/reformat.yml
- name: centos
  description: CentOS kernels
  type: redhat
  file: centos.txt
  reformat: single
EOT

if ! make -j -k crawl-centos-no-docker 2> >(tee /tmp/make-crawl-stderr >&2) ; then
    touch /tmp/crawl-failed
fi

#./scripts/restore-removed

make sync
git --no-pager diff kernel-package-lists/

# generate manifest
make manifest
cat kernel-package-lists/manifest.yml
git --no-pager diff kernel-package-lists/manifest.yml

# prepare artifacts
rm -rf .build-data/downloads
rm -rf .build-data/packages

mkdir -p ${ARTIFACT_DIR}/build-data
mkdir -p ${ARTIFACT_DIR}/kernel-package-lists

cp -r .build-data ${ARTIFACT_DIR}/build-data
cp kernel-package-lists/manifest.yml ${ARTIFACT_DIR}/kernel-package-lists/manifest.yaml

# push changes
echo $PULL_BASE_REF
BRANCH="$(echo "$JOB_SPEC" | jq -r '.extra_refs[0].base_ref')"

if [[ "$CIRCLE_BRANCH" =~ ^(master|main|ddolgov-feature-crawling)$ ]]; then
    make robo-crawl-commit
fi;
