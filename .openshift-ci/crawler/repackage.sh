#!/usr/bin/env bash
set -eo pipefail

# Assume we need to run in staging mode unconditionally for testing purposes.

source .openshift-ci/env.sh
source .openshift-ci/google-cloud-sdk/install.sh
source .openshift-ci/google-cloud-sdk/init.sh
source .openshift-ci/crawler/setup-staging.sh

export ROOT_DIR=/tmp/repackaging
mkdir -p ${ROOT_DIR}

mkdir -p ${ROOT_DIR}/.build-data/cache
touch ${ROOT_DIR}/.build-data/cache/cache.yml
cat ${ROOT_DIR}/.build-data/cache/cache.yml
cat kernel-package-lists/manifest.yml

shopt -s extglob
rm kernel-package-lists/!(centos.txt|centos-uncrawled.txt|rhel.txt|rhel-uncrawled.txt|reformat.yml)
cat <<EOT > kernel-package-lists/reformat.yml
- name: centos
  description: CentOS kernels
  type: redhat
  file: centos.txt
  reformat: single

- name: rhel
  description: RHEL
  type: redhat
  file: rhel.txt
  reformat: single

EOT

echo "List files..."
make list-files

echo "Download packages..."
make download-packages
#make packers

echo "Repackage..."
make repackage-no-docker

mkdir -p .build-data/bundles
ls -lhR .build-data/bundles

echo "Upload bundles..."
make upload-bundles

cp -r .build-data/gsutil-download.log ${ARTIFACT_DIR}/build-data/
cp -r .build-data/cache ${ARTIFACT_DIR}/build-data/cache
