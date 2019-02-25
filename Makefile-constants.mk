# Repository root directory. Must be set.
ifndef ROOT_DIR
$(error ROOT_DIR is not set)
endif

# Directory to output crawled text files into.
CRAWLED_PACKAGE_DIR = $(ROOT_DIR)/kernel-package-lists

# GCS bucket for storing kernel header packages
KERNEL_PACKAGE_BUCKET = gs://stackrox-kernel-packages

# GCS bucket for storing kernel bundles
KERNEL_BUNDLE_BUCKET = gs://stackrox-kernel-bundles
