#!/usr/bin/env bash

# To compile and run a kernel module on the Docker for Desktop linuxkit kernel,
# we need the struct randomization seed, which is auto-generated at compile-time.
# The seed is in the linux headers for the docker kernels, which, as of March
# 2021, is not provided in the installation DMG file[1], but rather in a seperate
# docker image[2]. There isn't a readily apparent way to match the image to dmg,
# without compairing all pairs for a match. This script takes a list of Docker
# Desktop for Mac DMG installer file URLs and a list of docker layer URLs and
# prints only the docker layer URLs that correspond to a kernel found in one of
# the DMG files.

# [1] (https://github.com/docker/for-mac/issues/3223)
# [2] (https://hub.docker.com/r/docker/for-desktop-kernel)

DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DATA_DIR="${BUILD_DATA_DIR:-${DIR}/../../.build-data}"
PACKAGE_DIR="${BUILD_DATA_DIR}/packages"

die() {
    echo >&2 "$@"
    exit 1
}

simplify() {
    echo "$1" | tr -c 'a-zA-Z0-9_.\n-' '-'
}

kernel_bin_sha() {
    kernel_file="$1"
    sha256sum "${kernel_file}" | cut -d' ' -f 1
}

kernel_sha_from_installer_dmg() {
    pkg="$1"
    if [[ ! -f "${PACKAGE_DIR}/$pkg" ]]; then
        die "file not found: $pkg"
    fi

    dmg_file="${PACKAGE_DIR}/$pkg"
    kernel_file="$(mktemp)"
    kernel_dmg_path="Docker/Docker.app/Contents/Resources/linuxkit/kernel"

    # Extract only the kernel from dmg, this requires a recent version of 7z
    7z x -so "${dmg_file}" "${kernel_dmg_path}" > "${kernel_file}"

    # Check kernel file is not empty/missing
    if [[ ! -s "${kernel_file}" ]]; then
        rm "${kernel_file}"
        die "empty or missing kernel file in $pkg"
    fi

    sha="$(kernel_bin_sha "${kernel_file}")"
    echo "${sha}"
    rm "${kernel_file}"
}

inspect_kernel_sha_from_kernel_image_layer() {
    pkg="$1"
    dmg_kernel_shas="$2"

    if [[ ! -f "${PACKAGE_DIR}/$pkg" ]]; then
        die "file not found: $pkg"
    fi

    layer_file="${PACKAGE_DIR}/$pkg"
    kernel_file="$(mktemp)"
    tar -x -O -f "${layer_file}" kernel > "${kernel_file}"

    sha="$(kernel_bin_sha "${kernel_file}")"

    if grep -q "${sha}" "${dmg_kernel_shas}" ; then
        echo "$pkg"
    fi
    rm "${kernel_file}"
}

main() {
  [[ -f "$1" && -f "$2" ]] || die "usage $0 <dmg-files.txt> <kernel-layer-files.txt>"

  set -euo pipefail
  dmg_kernel_shas="$(mktemp)"

  while IFS='' read -r line || [[ -n "$line" ]]; do
      kernel_sha_from_installer_dmg "$(simplify "$line")"
  done < "$1" | sort | uniq > "${dmg_kernel_shas}"

  while IFS='' read -r line || [[ -n "$line" ]]; do
      inspect_kernel_sha_from_kernel_image_layer "$(simplify "$line")" "${dmg_kernel_shas}"
  done < "$2"

  rm "${dmg_kernel_shas}"
}

main "$@"
