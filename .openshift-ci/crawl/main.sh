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
rm kernel-package-lists/!(centos.txt|centos-uncrawled.txt|rhel6.txt|rhel76-eus.txt|rhel7.txt|rhel81-eus.txt|rhel81.txt|rhel82-eus.txt|rhel82.txt|rhel84-eus.txt|rhel8-rhocp4.3.txt|rhel8-rhocp4.4.txt|rhel8-rhocp4.5.txt|rhel8.txt|reformat.yml)
cat <<EOT > kernel-package-lists/reformat.yml
- name: centos
  description: CentOS kernels
  type: redhat
  file: centos.txt
  reformat: single

- name: rhel6
  description: RHEL 6 Kernels
  type: redhat
  file: rhel6.txt
  reformat: single

- name: rhel7
  description: RHEL 7 Kernels
  type: redhat
  file: rhel7.txt
  reformat: single

- name: rhel76-eus
  description: RHEL 7.6 EUS Kernels
  type: redhat
  file: rhel76-eus.txt
  reformat: single

- name: rhel8
  description: RHEL 8 Kernels
  type: redhat
  file: rhel8.txt
  reformat: single

- name: rhel81
  description: RHEL 8.1 Kernels
  type: redhat
  file: rhel81.txt
  reformat: single

- name: rhel82
  description: RHEL 8.2 Kernels
  type: redhat
  file: rhel82.txt
  reformat: single

- name: rhel81-eus
  description: RHEL 8.1 EUS Kernels
  type: redhat
  file: rhel81-eus.txt
  reformat: single

- name: rhel82-eus
  description: RHEL 8.2 EUS Kernels
  type: redhat
  file: rhel82-eus.txt
  reformat: single

- name: rhel84-eus
  description: RHEL 8.4 EUS Kernels
  type: redhat
  file: rhel84-eus.txt
  reformat: single

- name: rhel8-rhocp4.3
  description: RHEL 8 OpenShift Container Platform 4.3
  type: redhat
  file: rhel8-rhocp4.3.txt
  reformat: single

- name: rhel8-rhocp4.4
  description: RHEL 8 OpenShift Container Platform 4.4
  type: redhat
  file: rhel8-rhocp4.4.txt
  reformat: single

- name: rhel8-rhocp4.5
  description: RHEL 8 OpenShift Container Platform 4.5
  type: redhat
  file: rhel8-rhocp4.5.txt
  reformat: single
EOT

if ! make -j -k crawl-centos-no-docker 2> >(tee /tmp/make-crawl-stderr >&2) ; then
    touch /tmp/crawl-failed
fi

if ! make -j -k crawl-rhel-no-docker 2> >(tee /tmp/make-crawl-stderr >&2) ; then
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
BRANCH="$(echo "$JOB_SPEC" | jq -r '.extra_refs[0].base_ref')"

if [[ "$CIRCLE_BRANCH" =~ ^(master|main)$ ]]; then
    make robo-crawl-commit
fi;
