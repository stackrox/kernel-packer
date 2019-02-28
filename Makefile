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
		-bucket-inventory-file .build-data/package-inventory.txt \
	> kernel-package-lists/manifest.yml

.PHONY: robo-crawl-commit
robo-crawl-commit:
	@./scripts/robo-crawl-commit $(CRAWLED_PACKAGE_DIR)

.PHONY: sync
sync:
	@mkdir -p .build-data/downloads
	@./scripts/sync $(CRAWLED_PACKAGE_DIR) $(KERNEL_PACKAGE_BUCKET) .build-data/downloads

.PHONY: crawled-inventory
crawled-inventory:
	@mkdir -p .build-data
	@./scripts/crawled-inventory $(CRAWLED_PACKAGE_DIR) > .build-data/crawled-inventory.txt

.PHONY: package-inventory
package-inventory:
	@mkdir -p .build-data
	@./scripts/package-inventory $(KERNEL_PACKAGE_BUCKET) > .build-data/package-inventory.txt

.PHONY: repackage
repackage: packers
	@mkdir -p .build-data/cache
	@touch .build-data/cache/cache.yml
	@go run ./tools/repackage-kernels/main.go \
		-manifest kernel-package-lists/manifest.yml \
		-cache-dir .build-data/cache \
		-pkg-dir .build-data/packages \
		-bundle-dir .build-data/bundles \
		-action build

.PHONY: combine-cache
combine-cache:
	@mkdir -p .build-data/cache
	@touch .build-data/cache/cache.yml
	@go run ./tools/repackage-kernels/main.go \
		-cache-dir .build-data/cache \
		-action combine

.PHONY: list-files
list-files:
	@mkdir -p .build-data/cache
	@touch .build-data/cache/cache.yml
	@go run ./tools/repackage-kernels/main.go \
		-manifest kernel-package-lists/manifest.yml \
		-cache-dir .build-data/cache \
		-prefix gs://stackrox-kernel-packages \
		-action files | tee .build-data/packages.txt

.PHONY: download-packages
download-packages:
	@mkdir -p .build-data/packages
	@gsutil -m cp -c -L .build-data/gsutil-download.log -I .build-data/packages < .build-data/packages.txt || true

.PHONY: upload-bundles
upload-bundles:
	@mkdir -p .build-data/bundles
	@find .build-data/bundles -name '*.tgz' | gsutil -m cp -c -L .build-data/gsutil-upload.log -I $(KERNEL_BUNDLE_BUCKET) || true

.PHONY: clean-cache
clean-cache:
	@rm -rf .build-data/cache/fragment-*

.PHONY: packers
packers:
	@make -C packers all
