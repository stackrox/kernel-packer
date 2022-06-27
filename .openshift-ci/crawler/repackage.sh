#!/usr/bin/env bash
set -eo pipefail

# Assume we need to run in staging mode unconditionally for testing purposes.

source .openshift-ci/env.sh
source .openshift-ci/google-cloud-sdk/install.sh
source .openshift-ci/google-cloud-sdk/init.sh
source .openshift-ci/crawler/setup-staging.sh

mkdir -p .build-data/cache
touch .build-data/cache/cache.yml
cat .build-data/cache/cache.yml
cat kernel-package-lists/manifest.yml

make list-files
make download-packages
#make packers
make repackage

mkdir -p .build-data/bundles
ls -lhR .build-data/bundles

make upload-bundles

cp -r .build-data/gsutil-download.log ${ARTIFACT_DIR}/build-data/
cp -r .build-data/cache ${ARTIFACT_DIR}/build-data/cache
