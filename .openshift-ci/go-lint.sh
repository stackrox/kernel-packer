#!/usr/bin/env bash
set -eo pipefail

# Perform basic linting activities for Go code:
# * Use goimport package, that does sorting of imports and gofmt
# * Run go tests

go get golang.org/x/tools/cmd/goimports

gofiles="$(find . -name '*.go' | grep -v /vendor/)"
test -z "$(goimports -l -local github.com/stackrox/kernel-packer $gofiles)"

go test -mod=mod -v ./...
