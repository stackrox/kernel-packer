#!/usr/bin/env bash
set -eo pipefail

source .openshift-ci/env.sh
source .openshift-ci/crawler/env.sh

# Assume we need to run in staging mode unconditionally for testing purposes.
source .openshift-ci/crawler/setup-staging.sh

if ! make -j -k crawl 2> >(tee /tmp/make-crawl-stderr >&2) ; then
    touch /tmp/crawl-failed
fi

if [[ -f /tmp/crawl-failed ]] || grep -Eq '\*\*\* \[[a-zA-Z0-9-]+\] Error' /tmp/make-crawl-stderr ; then
	echo >&2 "'make crawl' failed. See the output of the 'Crawl package repositories' step in the crawl job for further details."
	exit 1
fi

./scripts/restore-removed
