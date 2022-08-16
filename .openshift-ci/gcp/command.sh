#!/usr/bin/env bash

# The script runs a command with the kernel-packer repo as current working
# directory.

set -e

function die() {
    local STEP="$1"
    shift
    local ERROR_MESSAGE="$1"
    shift

    echo >&2 "$ERROR_MESSAGE"
    .openshift-ci/slack/notify.sh $STEP $ERROR_MESSAGE
    exit 1
}

runCommand() {
    local GCP_VM_NAME="$1"
    shift
    local GCP_VM_USER="$1"
    shift
    local GCP_VM_COMMAND="$1"
    shift

    [ -z "$GCP_VM_NAME" ] && die $GCP_VM_COMMAND "error: missing parameter GCP_VM_NAME"

    [ -z "$GCP_VM_USER" ] && die $GCP_VM_COMMAND "error: missing parameter GCP_VM_USER"

    [ -z "$GCP_VM_COMMAND" ] && die $GCP_VM_COMMAND "error: missing parameter GCP_VM_COMMAND"

    success=false
    for _ in {1..3}; do
        if gcloud compute ssh "${GCP_VM_USER}@${GCP_VM_NAME}"\
            --ssh-key-file="${GCP_SSH_KEY_FILE}"\
            --command "cd kernel-packer; ${GCP_VM_COMMAND}"; then
            success=true
            break
        else
            echo "Retrying in 5s ..."
            sleep 5
        fi
    done

    if [[ "$success" != "true" ]]; then
        die $GCP_VM_COMMAND "Failed to run command after 3 retries"
    fi

    return 0
}

main() {
    local GCP_VM_NAME="$1"
    shift
    local GCP_VM_USER="$1"
    shift
    local GCP_VM_COMMAND="$1"
    shift

    if ! command -v gcloud &> /dev/null
    then
        die $GCP_VM_COMMAND "gcloud is not found, stop..."
    fi

    echo "Running command $GCP_VM_COMMAND..."
    runCommand \
        "$GCP_VM_NAME"\
        "$GCP_VM_USER"\
        "$GCP_VM_COMMAND"
}

COMMAND=$@

source .openshift-ci/env.sh
source .openshift-ci/google-cloud-sdk/install.sh
source .openshift-ci/google-cloud-sdk/init.sh

main "kernel-packer-osci" "${GCP_SSH_KEY_USER}" $COMMAND
