ROOT_DIR = ./..
include ../Makefile-constants.mk

.DEFAULT_GOAL = all
.PHONY: all
all: crawl

.PHONY: build-crawl-container
build-crawl-container: Dockerfile kernel-crawler.py
	docker build -t kernel-crawler .

.PHONY: crawl-centos
crawl-centos: build-crawl-container
	docker run --rm -i kernel-crawler crawl CentOS --preserve-removed-urls < $(CRAWLED_PACKAGE_DIR)/centos.txt > /tmp/centos_urls_tmp.json
	docker run --rm -i kernel-crawler output-from-json crawled < /tmp/centos_urls_tmp.json > $(CRAWLED_PACKAGE_DIR)/centos.txt
	# Inline sed is there to remove spurious blank lines
	docker run --rm -i kernel-crawler output-from-json removed < /tmp/centos_urls_tmp.json | sed -e '/^$$/d' >> $(CRAWLED_PACKAGE_DIR)/centos-uncrawled.txt
	rm /tmp/centos_urls_tmp.json

.PHONY: crawl-kops
crawl-kops: build-crawl-container
	# The kbuild tools are required for each major version of the kernel for Debian.
	echo 'http://http.us.debian.org/debian/pool/main/l/linux-tools/linux-kbuild-4.4_4.4-4~bpo8+1_amd64.deb' > $(CRAWLED_PACKAGE_DIR)/kops.txt
	docker run --rm -i --entrypoint python3 kernel-crawler repo-crawler.py --print apt http://dist.kope.io/apt jessie main --match-prefix=Package=linux-headers-4 | sort >> $(CRAWLED_PACKAGE_DIR)/kops.txt

.PHONY: crawl-debian
crawl-debian: build-crawl-container
	docker run --rm -i kernel-crawler crawl Debian | sort > $(CRAWLED_PACKAGE_DIR)/debian.txt

.PHONY: crawl-amazon
crawl-amazon: build-crawl-container
	# Amazon doesn't actually publish a GPG signature for the package manifest, so
	# we don't actually supply that argument here.
	docker run --rm -i --entrypoint python3 kernel-crawler repo-crawler.py --print yum http://amazonlinux.us-west-2.amazonaws.com/2017.12/core/latest/x86_64/mirror.list --match-exact=name=kernel-devel | sort > $(CRAWLED_PACKAGE_DIR)/amazon.txt

.PHONY: crawl
crawl: build-crawl-container crawl-kops crawl-amazon crawl-debian
	docker run --rm -i kernel-crawler crawl CoreOS > $(CRAWLED_PACKAGE_DIR)/coreos.txt
	docker run --rm -i kernel-crawler crawl Container-OptimizedOS > $(CRAWLED_PACKAGE_DIR)/cos.txt
	docker run --rm -i kernel-crawler crawl Ubuntu > $(CRAWLED_PACKAGE_DIR)/ubuntu-standard.txt
	docker run --rm -i kernel-crawler crawl Ubuntu-AWS > $(CRAWLED_PACKAGE_DIR)/ubuntu-aws.txt
	docker run --rm -i kernel-crawler crawl Ubuntu-Azure > $(CRAWLED_PACKAGE_DIR)/ubuntu-azure.txt
	docker run --rm -i kernel-crawler crawl Ubuntu-GKE > $(CRAWLED_PACKAGE_DIR)/ubuntu-gke.txt
	docker run --rm -i kernel-crawler crawl Ubuntu-GCP > $(CRAWLED_PACKAGE_DIR)/ubuntu-gcp.txt
