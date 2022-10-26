#!/usr/bin/env bash
set -eo pipefail

source .openshift-ci/env.sh
source .openshift-ci/crawler/env.sh

# Assume we need to run in staging mode unconditionally for testing purposes.
source .openshift-ci/crawler/setup-staging.sh

# shellcheck source=SCRIPTDIR=scripts/lib.sh
source .openshift-ci/scripts/lib.sh

echo "Sync..."
make sync
git --no-pager diff kernel-package-lists/

# generate manifest
echo "Manifest..."
make manifest
cat kernel-package-lists/manifest.yml
git --no-pager diff kernel-package-lists/manifest.yml

# prepare artifacts
echo "Artifacts..."
rm -rf .build-data/downloads
rm -rf .build-data/packages

if ! is_in_PR_context; then
    echo "Is not in PR context"
fi

#if ! is_in_PR_context; then
#    make robo-crawl-commit
#fi
