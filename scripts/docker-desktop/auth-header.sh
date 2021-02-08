#!/usr/bin/env bash

set -euo pipefail

DOCKER_AUTH_URL="https://auth.docker.io/token?service=registry.docker.io&scope=repository"
IMAGE="docker/for-desktop-kernel"
echo "Authorization: Bearer $(curl --silent --header 'GET' "${DOCKER_AUTH_URL}:${IMAGE}:pull" | jq -r '.token')"
