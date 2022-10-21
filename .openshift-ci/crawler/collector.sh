#!/usr/bin/env bash
set -eo pipefail

source .openshift-ci/env.sh
source .openshift-ci/crawler/env.sh

# Assume we need to run in staging mode unconditionally for testing purposes.
source .openshift-ci/crawler/setup-staging.sh

if [[ "$BRANCH" =~ ^(master|main)$ ]]; then
    echo "Collector commit..."
    make robo-collector-commit
fi;
