#!/usr/bin/env bash
set -eo pipefail

source .openshift-ci/env.sh
source .openshift-ci/crawler/env.sh

# shellcheck source=SCRIPTDIR=scripts/lib.sh
source .openshift-ci/scripts/lib.sh

# Assume we need to run in staging mode unconditionally for testing purposes.
source .openshift-ci/crawler/setup-staging.sh

if ! is_in_PR_context; then
    echo "Not in PR context"
else
    echo "In PR context"
fi;

#if ! is_in_PR_context; then
#    echo "Collector commit..."
#    make robo-collector-commit
#fi;
