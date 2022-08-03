#!/usr/bin/env bash

# The functionality below was copied from the collector envbuilder script and
# adjusted to the crawler requirements. Further reconciliation with similar
# script from the collector repo is needed.

set -e

function die() {
    echo >&2 "$@"
    exit 1
}

createGCPVM() {
    local GCP_VM_NAME="$1"
    shift
    local GCP_IMAGE_PROJECT="$1"
    shift
    local GCP_IMAGE_FAMILY="$1"
    shift

    [ -z "$GCP_VM_NAME" ] && die "error: missing parameter GCP_VM_NAME"
    [ -z "$GCP_IMAGE_FAMILY" ] && die "error: missing parameter GCP_IMAGE_FAMILY"
    [ -z "$GCP_IMAGE_PROJECT" ] && die "error: missing parameter GCP_IMAGE_PROJECT"

    success=false
    # Three attempts is sometimes not enough.
    for _ in {1..3}; do
        # As crawler needs to have an access the packages/bundles GSC buckets
        # and necessary secrets, it requires storage-rw (GSC buckets) and
        # cloud-platform (secrets) scopes.
        #
        # Downloading packages may consume quite a lot of space, 300GB gives us
        # a small buffer for that (at the moment it takes ~240GB), but it makes
        # sense either to monitor it somehow and throw an obvious error when
        # there is not enough space, or change the logic to process packages
        # in batches and remove them.
        #
        # Note that starting from n2-standard-32 there is a posibility to use
        # certain networking optimizations (see --network-performance-configs
        # and --network-interface options), which could be beneficial to the
        # networking heavy parts of crawling. Unfortunately in some GCP
        # projects there is a limit on how large an allocated instance could
        # be.
        #
        # One also could specify a service account for the VM to use, which is
        # convenient for testing purposes. But turns out it requires some
        # strange self-referencing IAM permissions, so we've removed it.
        if gcloud compute instances create \
            --image-family "$GCP_IMAGE_FAMILY" \
            --image-project "$GCP_IMAGE_PROJECT" \
            --scopes="storage-rw,cloud-platform"\
            --machine-type n2-standard-16 \
            --labels="stackrox-kernel-crawler-osci=true,stackrox-osci-job=${BUILD_ID}" \
            --boot-disk-size=300GB \
            "$GCP_VM_NAME"; then
            success=true
            break
        else
            gcloud compute instances delete "$GCP_VM_NAME"
        fi
    done

    if [[ "$success" != "true" ]]; then
        die "Could not boot instance"
    fi

    gcloud compute instances add-metadata "$GCP_VM_NAME" --metadata serial-port-logging-enable=true
    gcloud compute instances describe --format json "$GCP_VM_NAME"
    echo "Instance created successfully: $GCP_VM_NAME"

    return 0
}

copy_secret() {
    local NAME="$1"
    local DEST="$2"
    local PERMS="$3"

    cp "/tmp/secret/stackrox-kernel-packer-crawl/$NAME" "$DEST"
    chmod "$PERMS" "$DEST"
}

main() {
    local GCP_VM_NAME="$1"
    shift
    local GCP_VM_TYPE="$1"
    shift
    local GCP_IMAGE_FAMILY="$1"
    shift

    if ! command -v gcloud &> /dev/null
    then
        die "gcloud is not found, stop..."
    fi

    # GCP_SSH_KEY_FILE is provided via env variables mounted from secrets
    echo "Set up ssh keys"
    mkdir -p "$(dirname "${GCP_SSH_KEY_FILE}")"
    chmod 0700 "$(dirname "${GCP_SSH_KEY_FILE}")"

    copy_secret GCP_SSH_KEY "${GCP_SSH_KEY_FILE}" 0600
    copy_secret GCP_SSH_KEY_PUB "${GCP_SSH_KEY_FILE}.pub" 0600

    echo "Creating the VM..."
    createGCPVM \
        "$GCP_VM_NAME"\
        "$GCP_VM_TYPE"\
        "$GCP_IMAGE_FAMILY"
}

main \
    "kernel-packer-osci" \
    "ubuntu-os-cloud" \
    "ubuntu-2004-lts" \
