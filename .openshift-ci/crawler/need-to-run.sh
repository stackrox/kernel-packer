#!/usr/bin/env bash
set -eo pipefail

# Verifies if the crawl job has to be executed, or needs to be skipped.

if [[ "${JOB_NAME}" == "periodic-ci-stackrox-kernel-packer-main-crawl-cron" ]]; then
    echo "Running scheduled cron job"
    exit 0

elif [[ "${JOB_NAME}" == "crawl-build" && "$OSCI_BRANCH" =~ ^(master|main)$ && "${CIRCLE_USERNAME}" != "roxbot" ]]; then
    echo "Running kernel crawler tasks on non-automated commit to default branch."
    exit 0
fi

.circleci/pr_has_label.sh "crawl"
if [[ $? -eq 0 ]]; then
    echo "PR has crawl label, running kernel-crawler."
    exit 0
fi

echo "Not running crawl job"
exit 1
