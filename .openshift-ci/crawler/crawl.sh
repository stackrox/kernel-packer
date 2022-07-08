#!/usr/bin/env bash
set -eo pipefail

# Assume we need to run in staging mode unconditionally for testing purposes.
source .openshift-ci/env.sh
source .openshift-ci/google-cloud-sdk/install.sh
source .openshift-ci/google-cloud-sdk/init.sh
source .openshift-ci/crawler/setup-staging.sh

export ROOT_DIR=.
#mkdir -p ${ROOT_DIR}

if ! make SHELL="sh -x" -j -k crawl-centos-no-docker 2> >(tee /tmp/make-crawl-stderr >&2) ; then
    touch /tmp/crawl-failed
fi

#if ! make -j -k crawl-rhsm-no-docker 2> >(tee /tmp/make-crawl-stderr >&2) ; then
    #touch /tmp/crawl-failed
#fi

#./scripts/restore-removed

echo "Sync..."
make SHELL="sh -x" sync
git --no-pager diff kernel-package-lists/

# generate manifest
echo "Manifest..."
make SHELL="sh -x" manifest
cat kernel-package-lists/manifest.yml
git --no-pager diff kernel-package-lists/manifest.yml

# prepare artifacts
echo "Artifacts..."
rm -rf .build-data/downloads
rm -rf .build-data/packages

mkdir -p ${SHARED_DIR}/build-data
mkdir -p ${SHARED_DIR}/kernel-package-lists

cp -r .build-data ${SHARED_DIR}/build-data
cp kernel-package-lists/manifest.yml ${SHARED_DIR}/kernel-package-lists/manifest.yaml

#if [[ "$BRANCH" =~ ^(master|main|ddolgov-feature-crawling)$ ]]; then
    #make robo-crawl-commit
#fi;
