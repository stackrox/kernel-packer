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

.PHONY: robo-commit
robo-commit:
	@./scripts/robo-commit $(CRAWLED_PACKAGE_DIR)

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
repackage:
	@mkdir -p .build-data/cache
	@touch .build-data/cache/cache.yml
	@go run ./tools/repackage-kernels/main.go \
		-manifest kernel-package-lists/manifest.yml \
		-cache-dir .build-data/cache \
		-pkg-dir .build-data/packages \
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

.PHONY: download-files
download-files:
	@mkdir -p .build-data/packages
	@gsutil -m cp -c -L .build-data/gsutil.log -I .build-data/packages < .build-data/packages.txt || true

.PHONY: clean-cache
clean-cache:
	@rm -rf .build-data/cache/fragment-*
