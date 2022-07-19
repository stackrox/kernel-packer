#!/usr/bin/env bash
set -eo pipefail

source .openshift-ci/env.sh
source .openshift-ci/crawler/env.sh

# Assume we need to run in staging mode unconditionally for testing purposes.
source .openshift-ci/crawler/setup-staging.sh

if ! make -j -k crawl 2> >(tee /tmp/make-crawl-stderr >&2) ; then
touch /tmp/crawl-failed
fi

./scripts/restore-removed
