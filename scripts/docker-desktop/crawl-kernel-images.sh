#!/usr/bin/env bash

# Crawl tags of the docker for desktop kernel images and blob URL of each non-empty layer
# Image details are here https://hub.docker.com/r/docker/for-desktop-kernel
# and here: https://github.com/linuxkit/linuxkit/blob/master/kernel/Dockerfile

set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"

REGISTRY_URL="https://registry-1.docker.io/v2"
REPO_URL="https://registry.hub.docker.com/v1/repositories"
TAG_PATTERN="^[0-9]\+\.[0-9]\+\.[0-9]\+-[a-z0-9]\{40\}.*$"
IMAGE="docker/for-desktop-kernel"

# Get all tags for the 'docker/for-desktop-kernel' that match the pattern
get_image_tags() {
  curl --silent "${REPO_URL}/${IMAGE}/tags" | \
    jq -r '.[].name' | grep "${TAG_PATTERN}"
}

# Query the layer info for a tag and print a URL for each non-empty layer
get_image_layer_urls() {
  local tag="$1"
  local auth_header="$2"
  manifest="$(curl --silent --request 'GET' --header "${auth_header}" "${REGISTRY_URL}/${IMAGE}/manifests/${tag}")"

  # shellcheck disable=SC2046
  read -r -a throwaway <<< $( jq -r '.history[].v1Compatibility' <<< "${manifest}" | jq '.throwaway' )

  # shellcheck disable=SC2046
  read -r -a layer_shas <<< $( jq -r '.fsLayers[].blobSum' <<< "${manifest}" )

  [[ "${#throwaway[@]}" == "${#layer_shas[@]}" ]] || exit 1

  for i in "${!layer_shas[@]}" ; do
    [[ "${throwaway[$i]}" != "true" ]] || continue
    echo "${REGISTRY_URL}/${IMAGE}/blobs/${layer_shas[$i]}"
  done
}

main() {
    auth_header="$("${DIR}/auth-header.sh")"
    tags=("$(get_image_tags)")
    for tag in ${tags[*]}; do
        get_image_layer_urls "${tag}" "${auth_header}"
    done | sort | uniq
}

main
