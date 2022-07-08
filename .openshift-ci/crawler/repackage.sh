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
cp ${SHARED_DIR}/kernel-package-lists/manifest.yaml kernel-package-lists/manifest.yml
cat kernel-package-lists/manifest.yml

echo "List files..."
make SHELL="sh -x" list-files

echo "Download packages..."
make SHELL="sh -x" download-packages
#make packers

echo "Repackage..."
make SHELL="sh -x" repackage-no-docker

mkdir -p .build-data/bundles
ls -lhR .build-data/bundles

echo "Upload bundles..."
make SHELL="sh -x" upload-bundles

cp -r .build-data/gsutil-download.log ${SHARED_DIR}/build-data/
cp -r .build-data/cache ${SHARED_DIR}/build-data/cache
