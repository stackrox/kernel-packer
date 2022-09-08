#!/usr/bin/env bash
set -eo pipefail

source .openshift-ci/env.sh
source .openshift-ci/crawler/env.sh

# Assume we need to run in staging mode unconditionally for testing purposes.
source .openshift-ci/crawler/setup-staging.sh

# Sanity check fragments
ls -lh .build-data/cache

echo "Combine cache..."
make combine-cache

echo "Clean cache..."
make clean-cache

echo "Sanity check bundles..."
IFS=',' read -r -a bucket_names <<< "${KERNEL_BUNDLE_BUCKET}"
for bucket_name in "${bucket_names[@]}"; do
  echo "Kernel versions in ${bucket_name}"
  gsutil ls "${bucket_name}/**.tgz" | \
    sed 's|^.*bundle-||' | sed 's|\.tgz$||' | sort || true
done

gsutil cp .build-data/cache/cache.yml "${bucket_names[0]}/cache.yml"
