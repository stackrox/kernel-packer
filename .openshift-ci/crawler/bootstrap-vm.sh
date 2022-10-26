#!/usr/bin/env bash

set -ex

# This script bootstraps a freshly created GCP VM by copying into it and
# running an init script.

# shellcheck source=SCRIPTDIR=scripts/lib.sh
source ".openshift-ci/scripts/lib.sh"

function die() {
    local STEP="$1"
    shift
    local ERROR_MESSAGE="$1"
    shift

    echo >&2 "$ERROR_MESSAGE"
    .openshift-ci/slack/notify.sh "$STEP" "$ERROR_MESSAGE"
    exit 1
}

copyAndRunInitScript() {
    local GCP_VM_NAME="$1"
    shift

    [ -z "$GCP_VM_NAME" ] && die "Bootstrap" "error: missing parameter GCP_VM_NAME"

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
        die "Bootstrap" "Failed to copy the init script after 3 retries"
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
        die "Bootstrap" "Failed to run the init script after 3 retries"
    fi

    return 0
}

main() {
    local GCP_VM_NAME="$1"
    shift

    export BRANCH="$(get_branch)"
    export SHARED_DIR=/tmp/

    # Branch point to the currently tested project branch, build id is a unique
    # Prow build identifier, shared directory is a leftover only used for
    # artifacts exchange and could be removed in the future.
    echo "BRANCH=${BRANCH}, BUILD_ID=${BUILD_ID}, SHARED_DIR=${SHARED_DIR}"
    envsubst '$${BUILD_ID} $${BRANCH} $${SHARED_DIR}' \
        < .openshift-ci/crawler/init.sh \
        > /tmp/init.sh

    if ! command -v gcloud &> /dev/null
    then
        die "Bootstrap" "gcloud is not found, stop..."
    fi

    echo "Copying and executing init script..."
    copyAndRunInitScript "$GCP_VM_NAME"

    echo "Uploading PR data..."

    success=false
    for _ in {1..3}; do
        if gcloud compute scp /tmp/ci-data.sh "$GCP_VM_NAME:/tmp/ci-data.sh"; then
            success=true
            break
        else
            echo "Retrying in 5s ..."
            sleep 5
        fi
    done

    if [[ "$success" != "true" ]]; then
        die "Bootstrap" "Failed to upload ci-data"
    fi
}

main "kernel-packer-osci-${PROW_JOB_ID}"
