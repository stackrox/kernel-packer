#!/usr/bin/env bash
set -eo pipefail

source .openshift-ci/env.sh
source .openshift-ci/crawler/env.sh

# Assume we need to run in staging mode unconditionally for testing purposes.
source .openshift-ci/crawler/setup-staging.sh

mkdir -p .build-data/cache

gsutil cp gs://${KERNEL_BUNDLE_BUCKET}/cache.yml .build-data/cache/cache.yml || true
touch .build-data/cache/cache.yml
cat .build-data/cache/cache.yml
cat kernel-package-lists/manifest.yml

echo "List files..."
make list-files

echo "Download packages..."
make download-packages
make packers

echo "Repackage..."
make repackage

mkdir -p .build-data/bundles
ls -lhR .build-data/bundles

echo "Upload bundles..."
make upload-bundles
