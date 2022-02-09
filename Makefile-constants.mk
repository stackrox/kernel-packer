# Repository root directory. Must be set.
ifndef ROOT_DIR
$(error ROOT_DIR is not set)
endif

# Resolve to an absolute directory, as it's required for Docker volume mounts.
ROOT_DIR_ABS = $(shell cd $(ROOT_DIR) && pwd)

# Directory to output ephemeral build data.
BUILD_DATA_DIR = $(ROOT_DIR_ABS)/.build-data

# Directory to output crawled text files into.
CRAWLED_PACKAGE_DIR = $(ROOT_DIR_ABS)/kernel-package-lists

# GCS bucket for storing kernel header packages
KERNEL_PACKAGE_BUCKET ?= gs://stackrox-kernel-packages

# GCS bucket for storing kernel bundles
KERNEL_BUNDLE_BUCKET ?= gs://stackrox-kernel-bundles

# Ubuntu FIPS contract URLs
UBUNTU_FIPS_ATTACH_URL ?= https://contracts.canonical.com/v1/resources/fips/context/machines/930f3ea7ac23ddc47f14216b9249d216
UBUNTU_FIPS_UPDATES_ATTACH_URL ?= https://contracts.canonical.com/v1/resources/fips-updates/context/machines/930f3ea7ac23ddc47f14216b9249d216
