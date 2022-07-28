#!/usr/bin/env bash

# The script runs a command with the kernel-packer repo as current working
# directory.

set -e

function die() {
    echo >&2 "$@"
    exit 1
}

runCommand() {
    local GCP_VM_NAME="$1"
    shift
    local GCP_VM_COMMAND="$1"
    shift

    [ -z "$GCP_VM_NAME" ] && die "error: missing parameter GCP_VM_NAME"

    [ -z "$GCP_VM_COMMAND" ] && die "error: missing parameter GCP_VM_COMMAND"

    success=false
    for _ in {1..3}; do
        if gcloud compute ssh "$GCP_VM_NAME" --command "cd kernel-packer; $GCP_VM_COMMAND"; then
            success=true
            break
        else
            echo "Retrying in 5s ..."
            sleep 5
        fi
    done

    if [[ "$success" != "true" ]]; then
        die "Failed to run command after 3 retries"
    fi

    return 0
}

main() {
    local GCP_VM_NAME="$1"
    shift
    local GCP_VM_COMMAND="$1"
    shift

    if ! command -v gcloud &> /dev/null
    then
        die "gcloud is not found, stop..."
    fi

    echo "Running command $GCP_VM_COMMAND..."
    runCommand "$GCP_VM_NAME" "$GCP_VM_COMMAND"
}

COMMAND=$@

source .openshift-ci/env.sh
source .openshift-ci/google-cloud-sdk/install.sh
source .openshift-ci/google-cloud-sdk/init.sh

main "kernel-packer-osci" $COMMAND
