# Crawl kernel package repositories and record discovered packages.
.PHONY: crawl
crawl:
	make -C kernel-crawler crawl

.PHONY: manifest
manifest:
	@mkdir -p .build-data
	@go run ./tools/generate-manifest -config kernel-package-lists/reformat.yml > .build-data/manifest.yml

.PHONY: repackage
repackage:
	@mkdir -p .build-data/fragments
	@go run ./tools/repackage-kernels/main.go \
		-manifest .build-data/manifest.yml \
		-cache-file .build-data/cache.yml \
		-cache-dir .build-data/fragments \
		-action build

.PHONY: combine-cache
combine-cache:
	@mkdir -p .build-data/fragments
	@go run ./tools/repackage-kernels/main.go \
		-cache-file .build-data/cache.yml \
		-cache-dir .build-data/fragments \
		-action combine

.PHONY: clean-cache
clean-cache:
	@rm -rf .build-data/fragments
