ROOT_DIR = .
include Makefile-constants.mk

# Crawl kernel package repositories and record discovered packages.
.PHONY: crawl
crawl:
	make -C kernel-crawler crawl

.PHONY: manifest
manifest: package-inventory
	@go run ./tools/generate-manifest/main.go \
		-config kernel-package-lists/reformat.yml \
		-bucket-inventory-file $(BUILD_DATA_DIR)/package-inventory.txt \
	> kernel-package-lists/manifest.yml

.PHONY: robo-crawl-commit
robo-crawl-commit:
	@./scripts/robo-crawl-commit $(CRAWLED_PACKAGE_DIR)

.PHONY: robo-collector-commit
robo-collector-commit:
	@./scripts/robo-collector-commit $(KERNEL_BUNDLE_BUCKET)

.PHONY: sync
sync:
	$(MAKE) download-packages
	$(MAKE) upload-packages

.PHONY: download-packages
download-packages:
	@mkdir -p $(BUILD_DATA_DIR)/downloads
	@scripts/download-packages $(CRAWLED_PACKAGE_DIR) $(KERNEL_PACKAGE_BUCKET) $(BUILD_DATA_DIR)/downloads

.PHONY: upload-packages
upload-packages:
	@scripts/upload-packages $(KERNEL_PACKAGE_BUCKET) $(BUILD_DATA_DIR)/downloads

.PHONY: crawled-inventory
crawled-inventory:
	@mkdir -p $(BUILD_DATA_DIR)
	@./scripts/crawled-inventory $(CRAWLED_PACKAGE_DIR) > $(BUILD_DATA_DIR)/crawled-inventory.txt

.PHONY: package-inventory
package-inventory:
	@mkdir -p $(BUILD_DATA_DIR)
	@./scripts/package-inventory $(KERNEL_PACKAGE_BUCKET) $(PACKAGE_INVENTORY_EXTRA_SRC) > $(BUILD_DATA_DIR)/package-inventory.txt

.PHONY: repackage
repackage: packers
	@mkdir -p $(BUILD_DATA_DIR)/cache
	@touch $(BUILD_DATA_DIR)/cache/cache.yml
	@go run ./tools/repackage-kernels/main.go \
		-manifest kernel-package-lists/manifest.yml \
		-cache-dir $(BUILD_DATA_DIR)/cache \
		-pkg-dir $(BUILD_DATA_DIR)/packages \
		-bundle-dir $(BUILD_DATA_DIR)/bundles \
		-action build \
		-ignore-errors

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
		-manifest kernel-package-lists/manifest.yml \
		-cache-dir $(BUILD_DATA_DIR)/cache \
		-prefix gs://stackrox-kernel-packages \
		-action files | tee $(BUILD_DATA_DIR)/packages.txt

.PHONY: download-packages-from-gcs
download-packages-from-gcs:
	@mkdir -p $(BUILD_DATA_DIR)/packages
	@gsutil -m cp -c -L $(BUILD_DATA_DIR)/gsutil-download.log -I $(BUILD_DATA_DIR)/packages < $(BUILD_DATA_DIR)/packages.txt || true

.PHONY: upload-bundles
upload-bundles:
	@mkdir -p $(BUILD_DATA_DIR)/bundles
	@find $(BUILD_DATA_DIR)/bundles -name '*.tgz' | gsutil -m cp -c -L $(BUILD_DATA_DIR)/gsutil-upload.log -I $(KERNEL_BUNDLE_BUCKET) || true

.PHONY: clean-cache
clean-cache:
	@rm -rf $(BUILD_DATA_DIR)/cache/fragment-*

.PHONY: packers
packers:
	@make -C packers all

crawl-%:
	@make -C kernel-crawler $@