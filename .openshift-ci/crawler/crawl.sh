#!/usr/bin/env bash
set -eo pipefail

# Assume we need to run in staging mode unconditionally for testing purposes.
source .openshift-ci/env.sh
source .openshift-ci/google-cloud-sdk/install.sh
source .openshift-ci/google-cloud-sdk/init.sh
source .openshift-ci/crawler/setup-staging.sh

export ROOT_DIR=.
#mkdir -p ${ROOT_DIR}

if ! make -j -k crawl-centos-no-docker 2> >(tee /tmp/make-crawl-stderr >&2) ; then
    touch /tmp/crawl-failed
fi

#if ! make -j -k crawl-rhsm-no-docker 2> >(tee /tmp/make-crawl-stderr >&2) ; then
    #touch /tmp/crawl-failed
#fi

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

#if [[ "$BRANCH" =~ ^(master|main|ddolgov-feature-crawling)$ ]]; then
    #make robo-crawl-commit
#fi;
