#!/usr/bin/env bash
set -eo pipefail

# Notify only on the main branch
if is_in_PR_context; then
    echo "Not notifying on PRs"
    exit 0
fi

source .openshift-ci/env.sh

WEBHOOK_URL=$SLACK_WEBHOOK_ONCALL
# job name is known
JOB_NAME="periodic-ci-stackrox-kernel-packer-master-kernel-crawling-periodic"
JOB_URL="https://prow.ci.openshift.org/view/gs/origin-ci-test/logs/${JOB_NAME}/${BUILD_ID}"
JOB_STEP=$1
ERROR_MESSAGE=$2

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BODY=$(cat "${SCRIPT_DIR}/template")

jq --null-input \
    --arg job_name "$JOB_NAME"\
    --arg job_url "$JOB_URL"\
    --arg job_step "$JOB_STEP"\
    --arg error_message "$ERROR_MESSAGE"\
    --arg mentions "@kernel-package-oncall"\
    "${BODY}" | \
    curl -XPOST -d @- \
        -H 'Content-Type: application/json'\
        "$WEBHOOK_URL"
