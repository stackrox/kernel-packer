#!/usr/bin/env bash

set -e

deleteGCPVM() {
    local GCP_VM_NAME="$1"
    shift

    [ -z "$GCP_VM_NAME" ] && \
        echo "error: missing parameter GCP_VM_NAME" && return 1

    success=false
    for _ in {1..3}; do
        if gcloud compute instances delete "$GCP_VM_NAME";
        then
            success=true
            break
        fi
    done

    if test ! "$success" = "true"; then
        echo "Could not delete instance."
        return 1
    fi

    echo "Instance deleted successfully: $GCP_VM_NAME"

    return 0
}

main() {
    local GCP_VM_NAME="$1"
    shift

    if ! command -v gcloud &> /dev/null
    then
        echo "gcloud is not found, stop..."
        exit
    fi

    echo "Deleting the VM..."
    deleteGCPVM "$GCP_VM_NAME"
}

main "kernel-packer-osci"
