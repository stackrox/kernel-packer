#!/usr/bin/env bash
set -exo pipefail

touch /tmp/ci-data.sh

if [[ -n "${REPO_OWNER}" ]]; then
    echo "export REPO_OWNER='${REPO_OWNER}'" >> /tmp/ci-data.sh
fi

if [[ -n "${REPO_NAME}" ]]; then
    echo "export REPO_NAME='${REPO_NAME}'" >> /tmp/ci-data.sh
fi

if [[ -n "${PULL_NUMBER}" ]]; then
    echo "export PULL_NUMBER='${PULL_NUMBER}'" >> /tmp/ci-data.sh
fi

if [[ -n "${PULL_BASE_REF}" ]]; then
    echo "export PULL_BASE_REF='${PULL_BASE_REF}'" >> /tmp/ci-data.sh
fi

if [[ -n "${CLONEREFS_OPTIONS}" ]]; then
    echo "export CLONEREFS_OPTIONS='${CLONEREFS_OPTIONS}'" >> /tmp/ci-data.sh
fi

if [[ -n "${JOB_SPEC}" ]]; then
    echo "export JOB_SPEC='${JOB_SPEC}'" >> /tmp/ci-data.sh
fi
