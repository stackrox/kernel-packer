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

CIRCLE_NODE_INDEX ?= "local"
