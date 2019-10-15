ROOT_DIR = ./..
include ../Makefile-constants.mk

# Prevent piped commands (like sort) from swallowing errors during crawl.
SHELL=/bin/bash -o pipefail

.DEFAULT_GOAL = all
.PHONY: all
all: crawl

.PHONY: build-crawl-container
build-crawl-container: Dockerfile kernel-crawler.py main.go
	docker build -t kernel-crawler .
	docker build -t rhel-login rhel-login

.PHONY: crawl-centos
crawl-centos: build-crawl-container
	docker run --rm -i kernel-crawler crawl CentOS --preserve-removed-urls < $(CRAWLED_PACKAGE_DIR)/centos.txt > /tmp/centos_urls_tmp.json
	docker run --rm -i kernel-crawler output-from-json crawled < /tmp/centos_urls_tmp.json | sort > $(CRAWLED_PACKAGE_DIR)/centos.txt
	# Inline sed is there to remove spurious blank lines
	docker run --rm -i kernel-crawler output-from-json removed < /tmp/centos_urls_tmp.json | sed -e '/^$$/d' | sort >> $(CRAWLED_PACKAGE_DIR)/centos-uncrawled.txt
	rm /tmp/centos_urls_tmp.json

.PHONY: crawl-kops
crawl-kops: build-crawl-container
	# The kbuild tools are required for each major version of the kernel for Debian.
	echo 'http://http.us.debian.org/debian/pool/main/l/linux-tools/linux-kbuild-4.4_4.4-4~bpo8+1_amd64.deb' > $(CRAWLED_PACKAGE_DIR)/kops.txt
	docker run --rm -i --entrypoint python3 kernel-crawler repo-crawler.py --print apt http://dist.kope.io/apt jessie main --match-prefix=Package=linux-headers-4 | sort >> $(CRAWLED_PACKAGE_DIR)/kops.txt

.PHONY: crawl-debian
crawl-debian: build-crawl-container
	echo 'http://security.debian.org/pool/updates/main/l/linux/linux-kbuild-4.9_4.9.110-3+deb9u6_amd64.deb' > $(CRAWLED_PACKAGE_DIR)/debian.txt
	docker run --rm -i kernel-crawler crawl Debian | sort >> $(CRAWLED_PACKAGE_DIR)/debian.txt

.PHONY: crawl-amazon
crawl-amazon: build-crawl-container
	# Amazon doesn't actually publish a GPG signature for the package manifest, so
	# we don't actually supply that argument here.
	docker run --rm -i --entrypoint python3 kernel-crawler repo-crawler.py --print yum http://amazonlinux.us-west-2.amazonaws.com/2017.12/core/latest/x86_64/mirror.list --match-exact=name=kernel-devel | sort > $(CRAWLED_PACKAGE_DIR)/amazon.txt

.PHONY: crawl-ubuntu-hwe
crawl-ubuntu-hwe: build-crawl-container
	docker run --rm -i kernel-crawler crawl Ubuntu-HWE > $(CRAWLED_PACKAGE_DIR)/ubuntu-hwe.txt

.PHONY: crawl-ubuntu-gke
crawl-ubuntu-gke: build-crawl-container
	docker run --rm -i kernel-crawler crawl Ubuntu-GKE > $(CRAWLED_PACKAGE_DIR)/ubuntu-gke.txt

.PHONY: crawl-oracle-uek
crawl-oracle-uek: build-crawl-container
	docker run --rm -i kernel-crawler crawl Oracle-UEK5 > $(CRAWLED_PACKAGE_DIR)/oracle-uek.txt

.PHONY: crawl-rhel
crawl-rhel: build-crawl-container
	# Trade a username & password for a certificate keypair that allows up to
	# authenticate with the RHEL package repos.
	@mkdir -p $(BUILD_DATA_DIR)/rhel-certs
	docker run --rm \
		-e REDHAT_USERNAME \
		-e REDHAT_PASSWORD \
		rhel-login:latest \
	| tar -C $(BUILD_DATA_DIR)/rhel-certs -xf -

	# Crawl for RHEL 6 kernel-devel packages.
	docker run --rm \
		-v "$(BUILD_DATA_DIR)/rhel-certs:/rhel-certs:ro" \
		--entrypoint /usr/bin/rhel-crawler \
		kernel-crawler:latest \
			-base-url https://cdn.redhat.com/content/dist/rhel/server/6/6Server/x86_64/os \
			-cert /rhel-certs/rhel-cert.pem \
			-key /rhel-certs/rhel-key.pem \
		> $(CRAWLED_PACKAGE_DIR)/rhel6.txt

	# Crawl for RHEL 7 kernel-devel packages.
	docker run --rm \
		-v "$(BUILD_DATA_DIR)/rhel-certs:/rhel-certs:ro" \
		--entrypoint /usr/bin/rhel-crawler \
		kernel-crawler:latest \
			-base-url https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/os \
			-cert /rhel-certs/rhel-cert.pem \
			-key /rhel-certs/rhel-key.pem \
		> $(CRAWLED_PACKAGE_DIR)/rhel7.txt

	# Crawl for RHEL 8 kernel-devel packages.
	docker run --rm \
		-v "$(BUILD_DATA_DIR)/rhel-certs:/rhel-certs:ro" \
		--entrypoint /usr/bin/rhel-crawler \
		kernel-crawler:latest \
			-base-url https://cdn.redhat.com/content/dist/rhel8/8/x86_64/baseos/os \
			-cert /rhel-certs/rhel-cert.pem \
			-key /rhel-certs/rhel-key.pem \
		> $(CRAWLED_PACKAGE_DIR)/rhel8.txt

.PHONY: crawl
crawl: build-crawl-container crawl-rhel crawl-centos crawl-kops crawl-amazon crawl-debian crawl-ubuntu-hwe crawl-ubuntu-gke crawl-oracle-uek
	docker run --rm -i kernel-crawler crawl CoreOS > $(CRAWLED_PACKAGE_DIR)/coreos.txt
	docker run --rm -i kernel-crawler crawl Container-OptimizedOS > $(CRAWLED_PACKAGE_DIR)/cos.txt
	docker run --rm -i kernel-crawler crawl Ubuntu > $(CRAWLED_PACKAGE_DIR)/ubuntu-standard.txt
	docker run --rm -i kernel-crawler crawl Ubuntu-AWS > $(CRAWLED_PACKAGE_DIR)/ubuntu-aws.txt
	docker run --rm -i kernel-crawler crawl Ubuntu-Azure > $(CRAWLED_PACKAGE_DIR)/ubuntu-azure.txt
	docker run --rm -i kernel-crawler crawl Ubuntu-GCP > $(CRAWLED_PACKAGE_DIR)/ubuntu-gcp.txt
	docker run --rm -i kernel-crawler crawl Minikube > $(CRAWLED_PACKAGE_DIR)/minikube.txt
