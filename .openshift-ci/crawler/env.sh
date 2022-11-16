#!/usr/bin/env bash

set -e

# These commands get only those credentials that are located in GCP Secret
# Manager. They vary in format, and have to be unified as env vars. Note that
# we always take the latest version of available values.

gcloud secrets versions access latest \
    --secret="collector-kernel-crawler-rhel-credentials" \
    | sed -e 's/^/export /' >> $BASH_ENV

echo >> $BASH_ENV

gcloud secrets versions access latest \
    --secret="collector-kernel-crawler-suse-credentials" \
    | sed -e 's/^/export /' >> $BASH_ENV

echo >> $BASH_ENV

gcloud secrets versions access latest \
    --secret="collector-kernel-crawler-ubuntu-credentials" \
    | sed -e 's/^/export /' >> $BASH_ENV

echo >> $BASH_ENV

echo "export GITHUB_TOKEN="$(gcloud secrets versions access latest \
    --secret="collector-github-token") >> $BASH_ENV

source $BASH_ENV
