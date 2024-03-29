ROOT_DIR = .
include Makefile-constants.mk

MANIFEST_FILE ?= "kernel-package-lists/manifest.yml"

bundles: repackage-all combine-all

repackage-all: repackage-pre list-files download-packages packers repackage repackage-post

combine-all: combine-cache clean-cache

crawl-all: crawl sync manifest

# Crawl kernel package repositories and record discovered packages.
.PHONY: crawl
crawl:
	make -C kernel-crawler crawl

# Crawl internal rhel repos and then sync the packages
#   Environment variables needed: REDHAT_USERNAME, REDHAT_PASSWORD, KERNEL_PACKAGE_BUCKET
#   GCP write access needed to upload files to $KERNEL_PACKAGE_BUCKET
.PHONY: sync-internal-with-crawl
sync-internal-with-crawl:
	make -C kernel-crawler crawl-rhel-internal
	@mkdir -p $(BUILD_DATA_DIR)/downloads
	@./scripts/sync $(CRAWLED_PACKAGE_DIR)/rhel9-rhocp4.13.txt $(KERNEL_PACKAGE_BUCKET) $(BUILD_DATA_DIR)/downloads
	@./scripts/sync $(CRAWLED_PACKAGE_DIR)/rhel9-rhocp4.14.txt $(KERNEL_PACKAGE_BUCKET) $(BUILD_DATA_DIR)/downloads

.PHONY: manifest
manifest: package-inventory
	@go run ./tools/generate-manifest/main.go \
		-config kernel-package-lists/reformat.yml \
		-bucket-inventory-file $(BUILD_DATA_DIR)/package-inventory.txt \
	> $(MANIFEST_FILE)

.PHONY: robo-crawl-commit
robo-crawl-commit:
	@./scripts/robo-crawl-commit $(CRAWLED_PACKAGE_DIR)

.PHONY: robo-collector-commit
robo-collector-commit:
	@./scripts/robo-collector-commit $(KERNEL_BUNDLE_BUCKET)

sync: export UBUNTU_ESM_INFRA_BEARER_TOKEN = $(shell ./scripts/ubuntu-esm-infra-token)
sync: export UBUNTU_FIPS_BEARER_TOKEN = $(shell ./scripts/ubuntu-fips-token $(UBUNTU_FIPS_ATTACH_URL))
sync: export UBUNTU_FIPS_UPDATES_BEARER_TOKEN = $(shell ./scripts/ubuntu-fips-token $(UBUNTU_FIPS_UPDATES_ATTACH_URL))

.PHONY: sync
sync:
	@mkdir -p $(BUILD_DATA_DIR)/downloads
	@./scripts/sync $(CRAWLED_PACKAGE_DIR) $(KERNEL_PACKAGE_BUCKET) $(BUILD_DATA_DIR)/downloads

.PHONY: crawled-inventory
crawled-inventory:
	@mkdir -p $(BUILD_DATA_DIR)
	@./scripts/crawled-inventory $(CRAWLED_PACKAGE_DIR) > $(BUILD_DATA_DIR)/crawled-inventory.txt

.PHONY: package-inventory
package-inventory:
	@mkdir -p $(BUILD_DATA_DIR)
	@./scripts/package-inventory $(KERNEL_PACKAGE_BUCKET) > $(BUILD_DATA_DIR)/package-inventory.txt

.PHONY: repackage-pre
repackage-pre:
	mkdir -p .build-data/cache
	touch .build-data/cache/cache.yml

.PHONY: repackage-post
repackage-post:
	mkdir -p .build-data/bundles

.PHONY: repackage
repackage: packers
	@mkdir -p $(BUILD_DATA_DIR)/cache
	@touch $(BUILD_DATA_DIR)/cache/cache.yml
	@go run ./tools/repackage-kernels/main.go \
		-manifest $(MANIFEST_FILE) \
		-cache-dir $(BUILD_DATA_DIR)/cache \
		-pkg-dir $(BUILD_DATA_DIR)/packages \
		-bundle-dir $(BUILD_DATA_DIR)/bundles \
		-action build

.PHONY: combine-cache
combine-cache:
	@mkdir -p $(BUILD_DATA_DIR)/cache
	@touch $(BUILD_DATA_DIR)/cache/cache.yml
	@go run ./tools/repackage-kernels/main.go \
		-cache-dir $(BUILD_DATA_DIR)/cache \
		-action combine

.PHONY: list-files
list-files:
	@mkdir -p $(BUILD_DATA_DIR)/cache
	@touch $(BUILD_DATA_DIR)/cache/cache.yml
	@go run ./tools/repackage-kernels/main.go \
		-manifest $(MANIFEST_FILE) \
		-cache-dir $(BUILD_DATA_DIR)/cache \
		-action files > $(BUILD_DATA_DIR)/packages.txt

.PHONY: download-packages
download-packages:
	@./scripts/download-packages $(BUILD_DATA_DIR) $(KERNEL_PACKAGE_BUCKET)

.PHONY: upload-bundles
upload-bundles:
	@./scripts/upload-bundles $(BUILD_DATA_DIR) $(KERNEL_BUNDLE_BUCKET)

.PHONY: clean-cache
clean-cache:
	@rm -rf $(BUILD_DATA_DIR)/cache/fragment-*

.PHONY: packers
packers:
	$(MAKE) -C packers all

crawl-%:
	$(MAKE) -C kernel-crawler $@
