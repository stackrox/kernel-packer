ROOT_DIR = ./..
include ../Makefile-constants.mk

# Prevent piped commands (like sort) from swallowing errors during crawl.
SHELL=/bin/bash -o pipefail

.DEFAULT_GOAL = all
.PHONY: all
all: crawl

.PHONY: tests
tests:
	docker build -t kernel-crawler-tests -f tests/Dockerfile .
	docker run --rm kernel-crawler-tests

.PHONY: build-crawl-container
build-crawl-container: Dockerfile kernel-crawler.py main.go tests
	docker build -t kernel-crawler .
	docker build -t rhel-login rhel-login

.PHONY: crawl-centos
crawl-centos: build-crawl-container
	./scripts/run-crawler.py crawl CentOS --preserve-removed-urls < $(CRAWLED_PACKAGE_DIR)/centos.txt > /tmp/centos_urls_tmp.json
	./scripts/run-crawler.py output-from-json crawled < /tmp/centos_urls_tmp.json | sort > $(CRAWLED_PACKAGE_DIR)/centos.txt
	# Inline sed is there to remove spurious blank lines
	./scripts/run-crawler.py output-from-json removed < /tmp/centos_urls_tmp.json | sed -e '/^$$/d' | sort >> $(CRAWLED_PACKAGE_DIR)/centos-uncrawled.txt
	rm /tmp/centos_urls_tmp.json

.PHONY: crawl-kops
crawl-kops: build-crawl-container
	# The kbuild tools are required for each major version of the kernel for Debian.
	echo 'http://http.us.debian.org/debian/pool/main/l/linux-tools/linux-kbuild-4.4_4.4-4~bpo8+1_amd64.deb' > $(CRAWLED_PACKAGE_DIR)/kops.txt
	./scripts/run-crawler.py --entrypoint python3 repo-crawler.py \
		--print apt http://dist.kope.io/apt jessie main --match-prefix=Package=linux-headers-4 | sort >> $(CRAWLED_PACKAGE_DIR)/kops.txt

.PHONY: crawl-gardenlinux
crawl-gardenlinux: build-crawl-container
	./scripts/run-crawler.py --entrypoint python3 garden-crawler.py > $(CRAWLED_PACKAGE_DIR)/gardenlinux.txt

.PHONY: crawl-debian
crawl-debian: build-crawl-container
	./scripts/run-crawler.py crawl Debian > $(CRAWLED_PACKAGE_DIR)/debian.txt

.PHONY: crawl-amazon
crawl-amazon: build-crawl-container
	# Amazon doesn't actually publish a GPG signature for the package manifest, so
	# we don't actually supply that argument here.
	./scripts/run-crawler.py --entrypoint python3 repo-crawler.py --print yum \
		http://amazonlinux.us-west-2.amazonaws.com/2/core/latest/x86_64/mirror.list \
		--match-exact=name=kernel-devel | sort > $(CRAWLED_PACKAGE_DIR)/amazon.txt
	./scripts/run-crawler.py --entrypoint python3 repo-crawler.py --print yum \
		http://amazonlinux.us-west-2.amazonaws.com/2/extras/kernel-5.4/latest/x86_64/mirror.list \
		--match-exact=name=kernel-devel | sort > $(CRAWLED_PACKAGE_DIR)/amazon-extras.txt
	./scripts/run-crawler.py --entrypoint python3 repo-crawler.py --print yum \
		http://amazonlinux.us-west-2.amazonaws.com/2/extras/kernel-5.10/latest/x86_64/mirror.list \
		--match-exact=name=kernel-devel | sort > $(CRAWLED_PACKAGE_DIR)/amazon-5.10.txt

.PHONY: crawl-ubuntu-hwe
crawl-ubuntu-hwe: build-crawl-container
	./scripts/run-crawler.py crawl Ubuntu-HWE > $(CRAWLED_PACKAGE_DIR)/ubuntu-hwe.txt

.PHONY: crawl-ubuntu-gke
crawl-ubuntu-gke: build-crawl-container
	./scripts/run-crawler.py crawl Ubuntu-GKE > $(CRAWLED_PACKAGE_DIR)/ubuntu-gke.txt

.PHONY: crawl-ubuntu-gcp
crawl-ubuntu-gcp: build-crawl-container
	./scripts/run-crawler.py crawl Ubuntu-GCP > $(CRAWLED_PACKAGE_DIR)/ubuntu-gcp.txt

.PHONY: crawl-ubuntu-azure
crawl-ubuntu-azure: build-crawl-container
	./scripts/run-crawler.py crawl Ubuntu-Azure > $(CRAWLED_PACKAGE_DIR)/ubuntu-azure.txt

.PHONY: crawl-ubuntu-aws
crawl-ubuntu-aws: build-crawl-container
	./scripts/run-crawler.py crawl Ubuntu-AWS > $(CRAWLED_PACKAGE_DIR)/ubuntu-aws.txt

crawl-ubuntu-esm: export UBUNTU_ESM_INFRA_BEARER_TOKEN = $(shell $(ROOT_DIR)/scripts/ubuntu-esm-infra-token)

.PHONY: crawl-ubuntu-esm
crawl-ubuntu-esm: build-crawl-container
	./scripts/run-crawler.py -e UBUNTU_ESM_INFRA_BEARER_TOKEN crawl Ubuntu-ESM > $(CRAWLED_PACKAGE_DIR)/ubuntu-esm.txt

crawl-ubuntu-fips: export UBUNTU_FIPS_BEARER_TOKEN = $(shell $(ROOT_DIR)/scripts/ubuntu-fips-token $(UBUNTU_FIPS_ATTACH_URL))
crawl-ubuntu-fips: export UBUNTU_FIPS_UPDATES_BEARER_TOKEN = $(shell $(ROOT_DIR)/scripts/ubuntu-fips-token $(UBUNTU_FIPS_UPDATES_ATTACH_URL))

.PHONY: crawl-ubuntu-fips
crawl-ubuntu-fips: build-crawl-container crawl-ubuntu-gcp-fips crawl-ubuntu-aws-fips crawl-ubuntu-azure-fips
	./scripts/run-crawler.py -e UBUNTU_FIPS_BEARER_TOKEN \
		-e UBUNTU_FIPS_UPDATES_BEARER_TOKEN \
		crawl Ubuntu-FIPS > $(CRAWLED_PACKAGE_DIR)/ubuntu-fips.txt

crawl-ubuntu-gcp-fips: build-crawl-container
	./scripts/run-crawler.py -e UBUNTU_FIPS_BEARER_TOKEN \
		-e UBUNTU_FIPS_UPDATES_BEARER_TOKEN \
		crawl Ubuntu-GCP-FIPS > $(CRAWLED_PACKAGE_DIR)/ubuntu-gcp-fips.txt

crawl-ubuntu-aws-fips: build-crawl-container
	./scripts/run-crawler.py -e UBUNTU_FIPS_BEARER_TOKEN \
		-e UBUNTU_FIPS_UPDATES_BEARER_TOKEN \
		crawl Ubuntu-AWS-FIPS > $(CRAWLED_PACKAGE_DIR)/ubuntu-aws-fips.txt

crawl-ubuntu-azure-fips: build-crawl-container
	./scripts/run-crawler.py -e UBUNTU_FIPS_BEARER_TOKEN \
		-e UBUNTU_FIPS_UPDATES_BEARER_TOKEN \
		crawl Ubuntu-Azure-FIPS > $(CRAWLED_PACKAGE_DIR)/ubuntu-azure-fips.txt

.PHONY: crawl-oracle-uek
crawl-oracle-uek: build-crawl-container
	./scripts/run-crawler.py crawl Oracle-UEK > $(CRAWLED_PACKAGE_DIR)/oracle-uek.txt

.PHONY: crawl-flatcar
crawl-flatcar: build-crawl-container
	./scripts/run-crawler.py crawl Flatcar > $(CRAWLED_PACKAGE_DIR)/flatcar.txt

.PHONY: crawl-flatcar-beta
crawl-flatcar-beta: build-crawl-container
	./scripts/run-crawler.py crawl Flatcar-Beta > $(CRAWLED_PACKAGE_DIR)/flatcar-beta.txt

.PHONY: crawl-suse
crawl-suse: build-crawl-container
	# Get repository auth tokens using SUSE mirroring proxy user/password credentials
	@mkdir -p $(BUILD_DATA_DIR)/suse-repo-tokens
	./suse/get-repo-tokens.sh > $(BUILD_DATA_DIR)/suse-repo-tokens/repos.json
	docker run --rm \
		-v "$(BUILD_DATA_DIR)/suse-repo-tokens:/suse-repo-tokens:ro" \
		-v "$(ROOT_DIR_ABS)/kernel-crawler/suse:/suse:ro" \
		--entrypoint /usr/bin/rhel-crawler \
		kernel-crawler:latest \
			-repos-file /suse-repo-tokens/repos.json \
			-repos-names-file /suse/repo-names.txt \
		> $(CRAWLED_PACKAGE_DIR)/suse.txt

.PHONY: build-rhsm-crawler
build-rhsm-crawler:
	docker build --tag rhsm-crawler $(CURDIR)/rhel-subscription-crawler

.PHONY: crawl-rhsm
crawl-rhsm: build-rhsm-crawler
	docker run -e RHSM_OFFLINE_TOKEN --rm -i -v $(CRAWLED_PACKAGE_DIR):/kernel-package-lists:ro rhsm-crawler:latest > $(CRAWLED_PACKAGE_DIR)/rhel.txt
	@sed -i 's/[@\^\r]//g' $(CRAWLED_PACKAGE_DIR)/rhel.txt

.PHONY: build-rhel-certs
build-rhel-certs: build-crawl-container
	# Trade a username & password for a certificate keypair that allows up to
	# authenticate with the RHEL package repos.
	@mkdir -p $(BUILD_DATA_DIR)/rhel-certs
	docker run --rm \
		-e REDHAT_USERNAME \
		-e REDHAT_PASSWORD \
		rhel-login:latest \
	| tar -C $(BUILD_DATA_DIR)/rhel-certs -xf -

	ls -alh $(BUILD_DATA_DIR)/rhel-certs

.PHONY: crawl-rhel-internal
crawl-rhel-internal: build-crawl-container build-rhel-certs
	# Crawl RHOCP 4.13
	./scripts/run-crawler.py \
		-v "$(BUILD_DATA_DIR)/rhel-certs:/rhel-certs:ro" \
		--entrypoint /usr/bin/rhel-crawler \
		-base-url https://ocp-artifacts.hosts.prod.psi.rdu2.redhat.com/pub/RHOCP/plashets/4.13/stream/el9/latest/x86_64/os/ \
		-cert /rhel-certs/rhel-cert.pem \
		-key /rhel-certs/rhel-key.pem \
		> $(CRAWLED_PACKAGE_DIR)/rhel9-rhocp4.13.txt

	# Crawl RHOCP 4.14
	./scripts/run-crawler.py \
		-v "$(BUILD_DATA_DIR)/rhel-certs:/rhel-certs:ro" \
		--entrypoint /usr/bin/rhel-crawler \
		-base-url https://ocp-artifacts.hosts.prod.psi.rdu2.redhat.com/pub/RHOCP/plashets/4.14/stream/el9/latest/x86_64/os/ \
		-cert /rhel-certs/rhel-cert.pem \
		-key /rhel-certs/rhel-key.pem \
		> $(CRAWLED_PACKAGE_DIR)/rhel9-rhocp4.14.txt

.PHONY: crawl-rhel
crawl-rhel: build-crawl-container build-rhel-certs
	# Crawl for RHEL 7 kernel-devel packages.
	./scripts/run-crawler.py \
		-v "$(BUILD_DATA_DIR)/rhel-certs:/rhel-certs:ro" \
		--entrypoint /usr/bin/rhel-crawler \
		-base-url https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/os \
		-cert /rhel-certs/rhel-cert.pem \
		-key /rhel-certs/rhel-key.pem \
		> $(CRAWLED_PACKAGE_DIR)/rhel7.txt

	# Crawl for RHEL 8 kernel-devel packages.
	./scripts/run-crawler.py \
		-v "$(BUILD_DATA_DIR)/rhel-certs:/rhel-certs:ro" \
		--entrypoint /usr/bin/rhel-crawler \
			-base-url https://cdn.redhat.com/content/dist/rhel8/8/x86_64/baseos/os \
			-cert /rhel-certs/rhel-cert.pem \
			-key /rhel-certs/rhel-key.pem \
		> $(CRAWLED_PACKAGE_DIR)/rhel8.txt

	# Crawl for RHEL 7.6 EUS (Extended Update Support) kernel-devel packages.
	./scripts/run-crawler.py \
		-v "$(BUILD_DATA_DIR)/rhel-certs:/rhel-certs:ro" \
		--entrypoint /usr/bin/rhel-crawler \
			-base-url https://cdn.redhat.com/content/eus/rhel/server/7/7.6/x86_64/os \
			-cert /rhel-certs/rhel-cert.pem \
			-key /rhel-certs/rhel-key.pem \
		> $(CRAWLED_PACKAGE_DIR)/rhel76-eus.txt

	# Crawl for RHEL 8.4 EUS (Extended Update Support) kernel-devel packages.
	./scripts/run-crawler.py \
		-v "$(BUILD_DATA_DIR)/rhel-certs:/rhel-certs:ro" \
		--entrypoint /usr/bin/rhel-crawler \
			-base-url https://cdn.redhat.com/content/eus/rhel8/8.4/x86_64/baseos/os \
			-cert /rhel-certs/rhel-cert.pem \
			-key /rhel-certs/rhel-key.pem \
		> $(CRAWLED_PACKAGE_DIR)/rhel84-eus.txt

	# Crawl for Red Hat OpenShift Container Platform 4.10 for RHEL 8 x86_64 (rhocp-4.10-for-rhel-8-x86_64-rpms)
	./scripts/run-crawler.py \
		-v "$(BUILD_DATA_DIR)/rhel-certs:/rhel-certs:ro" \
		--entrypoint /usr/bin/rhel-crawler \
			-base-url https://cdn.redhat.com/content/dist/layered/rhel8/x86_64/rhocp/4.10/os \
			-cert /rhel-certs/rhel-cert.pem \
			-key /rhel-certs/rhel-key.pem \
		> $(CRAWLED_PACKAGE_DIR)/rhel8-rhocp4.10.txt

	# Crawl for Red Hat OpenShift Container Platform 4.11 for RHEL 8 x86_64 (rhocp-4.11-for-rhel-8-x86_64-rpms)
	./scripts/run-crawler.py \
		-v "$(BUILD_DATA_DIR)/rhel-certs:/rhel-certs:ro" \
		--entrypoint /usr/bin/rhel-crawler \
			-base-url https://cdn.redhat.com/content/dist/layered/rhel8/x86_64/rhocp/4.11/os \
			-cert /rhel-certs/rhel-cert.pem \
			-key /rhel-certs/rhel-key.pem \
		> $(CRAWLED_PACKAGE_DIR)/rhel8-rhocp4.11.txt

	# Crawl for Red Hat OpenShift Container Platform 4.12 for RHEL 8 x86_64 (rhocp-4.12-for-rhel-8-x86_64-rpms)
	./scripts/run-crawler.py \
		-v "$(BUILD_DATA_DIR)/rhel-certs:/rhel-certs:ro" \
		--entrypoint /usr/bin/rhel-crawler \
			-base-url https://cdn.redhat.com/content/dist/layered/rhel8/x86_64/rhocp/4.12/os \
			-cert /rhel-certs/rhel-cert.pem \
			-key /rhel-certs/rhel-key.pem \
		> $(CRAWLED_PACKAGE_DIR)/rhel8-rhocp4.12.txt

.PHONY: crawl-fedora-coreos
crawl-fedora-coreos: build-crawl-container
	./scripts/run-crawler.py crawl Fedora-CoreOS > $(CRAWLED_PACKAGE_DIR)/fedora-coreos.txt

.PHONY: crawl-cos
crawl-cos: build-crawl-container
	./scripts/run-crawler.py crawl Container-OptimizedOS > $(CRAWLED_PACKAGE_DIR)/cos.txt

.PHONY: crawl-ubuntu-standard
crawl-ubuntu-standard: build-crawl-container
	./scripts/run-crawler.py crawl Ubuntu > $(CRAWLED_PACKAGE_DIR)/ubuntu-standard.txt

.PHONY: crawl-minikube
crawl-minikube: build-crawl-container
	./scripts/run-crawler.py \
		--entrypoint python3 \
		minikube-crawler.py > $(CRAWLED_PACKAGE_DIR)/minikube.txt

.PHONY: crawl
crawl: build-crawl-container crawl-suse crawl-rhel
crawl: crawl-centos crawl-kops crawl-amazon crawl-debian
crawl: crawl-ubuntu-esm crawl-ubuntu-gcp crawl-ubuntu-hwe
crawl: crawl-ubuntu-gke crawl-oracle-uek crawl-ubuntu-azure
crawl: crawl-flatcar crawl-flatcar-beta crawl-gardenlinux
crawl: crawl-ubuntu-aws crawl-fedora-coreos crawl-cos
crawl: crawl-ubuntu-standard crawl-minikube crawl-rhsm crawl-ubuntu-fips
