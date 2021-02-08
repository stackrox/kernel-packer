#!/usr/bin/env bash

set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"

REGISTRY_URL="https://registry-1.docker.io/v2"
REPO_URL="https://registry.hub.docker.com/v1/repositories"
IMAGE="docker/for-desktop-kernel"

get_image_tags() {
  curl --silent "${REPO_URL}/${IMAGE}/tags" | \
    jq -r '.[].name' | \
    grep "^[0-9]\+\.[0-9]\+\.[0-9]\+-[a-z0-9]\{40\}-amd64$"
}

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
