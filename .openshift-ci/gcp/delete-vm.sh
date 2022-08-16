#!/usr/bin/env bash

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

deleteGCPVM() {
    local GCP_VM_NAME="$1"
    shift

    [ -z "$GCP_VM_NAME" ] && die "VM delete" "error: missing parameter GCP_VM_NAME"

    success=false
    for _ in {1..3}; do
        if gcloud compute instances delete "$GCP_VM_NAME";
        then
            success=true
            break
        fi
    done

    if [[ "$success" != "true" ]]; then
        die "VM delete" "Could not delete instance"
    fi

    echo "Instance deleted successfully: $GCP_VM_NAME"

    return 0
}

main() {
    local GCP_VM_NAME="$1"
    shift

    if ! command -v gcloud &> /dev/null
    then
        die "VM delete" "gcloud is not found, stop..."
    fi

    echo "Deleting the VM..."
    deleteGCPVM "$GCP_VM_NAME"
}

main "kernel-packer-osci"
