#!/usr/bin/env bash
set -eo pipefail

shopt -s nullglob
for cred in /tmp/secret/**/[A-Z]*; do
    export "$(basename "$cred")"="$(cat "$cred")"
done

BRANCH="$(echo "$JOB_SPEC" | jq -r '.extra_refs[0].base_ref')"
