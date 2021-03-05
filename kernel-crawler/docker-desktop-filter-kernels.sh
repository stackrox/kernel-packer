#!/usr/bin/env bash

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
        die "missing $pkg"
    fi

    dmg_file="${PACKAGE_DIR}/$pkg"

    kernel_file="$(mktemp)"

    # This path is brittle and may change based on version
    kernel_dmg_path="Docker/Docker.app/Contents/Resources/linuxkit/kernel"

    # extract only the kernel from dmg
    7z x -so "${dmg_file}" "${kernel_dmg_path}" > "${kernel_file}"

    # check kernel file is not empty
    if [[ ! -s "${kernel_file}" ]]; then
        echo "installer dmg (skipped): $pkg"
        return
    fi

    sha="$(kernel_bin_sha "${kernel_file}")"
    echo "${sha}"

    rm "${kernel_file}"
}

inspect_kernel_sha_from_kernel_image_layer() {
    pkg="$1"
    dmg_kernel_shas="$2"

    if [[ ! -f "${PACKAGE_DIR}/$pkg" ]]; then
        die "missing $pkg"
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
