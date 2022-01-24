#!/usr/bin/env bash
# Generate an authorization bearer token string for a hardcoded docker image repository.

set -euo pipefail

TARGET=$1

if [[ "$TARGET" =~ ^https://registry-1.docker.io/v2/([a-z]+/[a-z]+)/.* ]]; then
    IMAGE=${BASH_REMATCH[1]}
else
    echo >&2 "Failed to match expression"
    return 1
fi

DOCKER_AUTH_URL="https://auth.docker.io/token?service=registry.docker.io&scope=repository"
echo "Authorization: Bearer $(curl --silent --header 'GET' "${DOCKER_AUTH_URL}:${IMAGE}:pull" | jq -r '.token')"
