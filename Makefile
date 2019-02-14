# Crawl kernel package repositories and record discovered packages.
.PHONY: crawl
crawl:
	make -C kernel-crawler crawl

.PHONY: manifest
manifest:
	@go run ./tools/generate-manifest -config kernel-package-lists/reformat.yml

.PHONY: robo-commit
robo-commit:
	@make -C kernel-crawler commit
