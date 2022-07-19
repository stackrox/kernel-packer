#!/usr/bin/env bash

set -e

# This script bootstraps a freshly created GCP VM by copying into it and
# running an init script.

copyAndRunInitScript() {
    local GCP_VM_NAME="$1"
    shift

    [ -z "$GCP_VM_NAME" ] && \
        echo "error: missing parameter GCP_VM_NAME" && return 1

    success=false
    for _ in {1..3}; do
        if gcloud compute scp /tmp/init.sh "$GCP_VM_NAME:/tmp/init.sh"; then
            success=true
            break
        else
            echo "Retrying in 5s ..."
            sleep 5
        fi
    done

    if [[ "$success" != "true" ]]; then
        echo "Failed to copy the init script after 3 retries"
        return 1
    fi

    success=false
    for _ in {1..3}; do
        if gcloud compute ssh "$GCP_VM_NAME" --command "bash /tmp/init.sh"; then
            success=true
            break
        else
            echo "Retrying in 5s ..."
            sleep 5
        fi
    done

    if [[ "$success" != "true" ]]; then
        echo "Failed to run the init script after 3 retries"
        return 1
    fi

    return 0
}

main() {
    local GCP_VM_NAME="$1"
    shift

    export BRANCH="$(echo "$JOB_SPEC" | jq -r '.extra_refs[0].base_ref')"
    export SHARED_DIR=/tmp/

    # Branch point to the currently tested project branch, build id is a unique
    # Prow build identifier, shared directory is a leftover only used for
    # artifacts exchange and could be removed in the future.
    echo "BRANCH=${BRANCH}, BUILD_ID=${BUILD_ID}, SHARED_DIR=${SHARED_DIR}"
    envsubst '$${BUILD_ID} $${BRANCH} $${SHARED_DIR}' \
        < .openshift-ci/crawler/init.sh \
        > /tmp/init.sh

    which gcloud || true

    echo "Copying and executing init script..."
    copyAndRunInitScript "$GCP_VM_NAME"
}

main "kernel-packer-osci"
