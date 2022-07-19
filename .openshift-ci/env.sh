#!/usr/bin/env bash
set -eo pipefail

# This script sets up only those credentials that are mounted from Prow. But it
# also serves as an entry point for many other activities, that's why it sets
# BASH_ENV as well.

echo "Load environment variables..."

export BASH_ENV=/tmp/bash_env

shopt -s nullglob
for cred in /tmp/secret/**/[A-Z]*; do
    export "$(basename "$cred")"="$(cat "$cred")"
done
