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

.PHONY: crawl-gardenlinux
crawl-gardenlinux: build-crawl-container
	docker run --rm -i --entrypoint bash kernel-crawler gardenlinux-crawler.sh >$(CRAWLED_PACKAGE_DIR)/gardenlinux.txt

.PHONY: crawl-debian
crawl-debian: build-crawl-container
	docker run --rm -i kernel-crawler crawl Debian > $(CRAWLED_PACKAGE_DIR)/debian.txt

.PHONY: crawl-amazon
crawl-amazon: build-crawl-container
	# Amazon doesn't actually publish a GPG signature for the package manifest, so
	# we don't actually supply that argument here.
	docker run --rm -i --entrypoint python3 kernel-crawler repo-crawler.py --print yum \
		http://amazonlinux.us-west-2.amazonaws.com/2/core/latest/x86_64/mirror.list \
		--match-exact=name=kernel-devel | sort > $(CRAWLED_PACKAGE_DIR)/amazon.txt
	docker run --rm -i --entrypoint python3 kernel-crawler repo-crawler.py --print yum \
		http://amazonlinux.us-west-2.amazonaws.com/2/extras/kernel-5.4/latest/x86_64/mirror.list \
		--match-exact=name=kernel-devel | sort > $(CRAWLED_PACKAGE_DIR)/amazon-extras.txt

.PHONY: crawl-ubuntu-hwe
crawl-ubuntu-hwe: build-crawl-container
	docker run --rm -i kernel-crawler crawl Ubuntu-HWE > $(CRAWLED_PACKAGE_DIR)/ubuntu-hwe.txt

.PHONY: crawl-ubuntu-gke
crawl-ubuntu-gke: build-crawl-container
	docker run --rm -i kernel-crawler crawl Ubuntu-GKE > $(CRAWLED_PACKAGE_DIR)/ubuntu-gke.txt

.PHONY: crawl-ubuntu-gcp
crawl-ubuntu-gcp: build-crawl-container
	docker run --rm -i kernel-crawler crawl Ubuntu-GCP > $(CRAWLED_PACKAGE_DIR)/ubuntu-gcp.txt

.PHONY: crawl-ubuntu-azure
crawl-ubuntu-azure: build-crawl-container
	docker run --rm -i kernel-crawler crawl Ubuntu-Azure > $(CRAWLED_PACKAGE_DIR)/ubuntu-azure.txt

.PHONY: crawl-ubuntu-aws
crawl-ubuntu-aws: build-crawl-container
	docker run --rm -i kernel-crawler crawl Ubuntu-AWS > $(CRAWLED_PACKAGE_DIR)/ubuntu-aws.txt

crawl-ubuntu-esm: export UBUNTU_ESM_INFRA_BEARER_TOKEN = $(shell $(ROOT_DIR)/scripts/ubuntu-esm-infra-token)

.PHONY: crawl-ubuntu-esm
crawl-ubuntu-esm: build-crawl-container
	docker run --rm -i -e UBUNTU_ESM_INFRA_BEARER_TOKEN kernel-crawler crawl Ubuntu-ESM > $(CRAWLED_PACKAGE_DIR)/ubuntu-esm.txt

.PHONY: crawl-oracle-uek
crawl-oracle-uek: build-crawl-container
	docker run --rm -i kernel-crawler crawl Oracle-UEK5 > $(CRAWLED_PACKAGE_DIR)/oracle-uek.txt

.PHONY: crawl-flatcar
crawl-flatcar: build-crawl-container
	docker run --rm -i kernel-crawler crawl Flatcar > $(CRAWLED_PACKAGE_DIR)/flatcar.txt

.PHONY: crawl-flatcar-beta
crawl-flatcar-beta: build-crawl-container
	docker run --rm -i kernel-crawler crawl Flatcar-Beta > $(CRAWLED_PACKAGE_DIR)/flatcar-beta.txt

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

	# Crawl for RHEL 8.1 kernel-devel packages.
	docker run --rm \
		-v "$(BUILD_DATA_DIR)/rhel-certs:/rhel-certs:ro" \
		--entrypoint /usr/bin/rhel-crawler \
		kernel-crawler:latest \
			-base-url https://cdn.redhat.com/content/dist/rhel8/8.1/x86_64/baseos/os \
			-cert /rhel-certs/rhel-cert.pem \
			-key /rhel-certs/rhel-key.pem \
		> $(CRAWLED_PACKAGE_DIR)/rhel81.txt

	# Crawl for RHEL 8.2 kernel-devel packages.
	docker run --rm \
		-v "$(BUILD_DATA_DIR)/rhel-certs:/rhel-certs:ro" \
		--entrypoint /usr/bin/rhel-crawler \
		kernel-crawler:latest \
			-base-url https://cdn.redhat.com/content/dist/rhel8/8.2/x86_64/baseos/os \
			-cert /rhel-certs/rhel-cert.pem \
			-key /rhel-certs/rhel-key.pem \
		> $(CRAWLED_PACKAGE_DIR)/rhel82.txt

	# Crawl for RHEL 7.6 EUS (Extended Update Support) kernel-devel packages.
	docker run --rm \
		-v "$(BUILD_DATA_DIR)/rhel-certs:/rhel-certs:ro" \
		--entrypoint /usr/bin/rhel-crawler \
		kernel-crawler:latest \
			-base-url https://cdn.redhat.com/content/eus/rhel/server/7/7.6/x86_64/os \
			-cert /rhel-certs/rhel-cert.pem \
			-key /rhel-certs/rhel-key.pem \
		> $(CRAWLED_PACKAGE_DIR)/rhel76-eus.txt

	# Crawl for RHEL 8.1 EUS (Extended Update Support) kernel-devel packages.
	docker run --rm \
		-v "$(BUILD_DATA_DIR)/rhel-certs:/rhel-certs:ro" \
		--entrypoint /usr/bin/rhel-crawler \
		kernel-crawler:latest \
			-base-url https://cdn.redhat.com/content/eus/rhel8/8.1/x86_64/baseos/os \
			-cert /rhel-certs/rhel-cert.pem \
			-key /rhel-certs/rhel-key.pem \
		> $(CRAWLED_PACKAGE_DIR)/rhel81-eus.txt

	# Crawl for RHEL 8.2 EUS (Extended Update Support) kernel-devel packages.
	docker run --rm \
		-v "$(BUILD_DATA_DIR)/rhel-certs:/rhel-certs:ro" \
		--entrypoint /usr/bin/rhel-crawler \
		kernel-crawler:latest \
			-base-url https://cdn.redhat.com/content/eus/rhel8/8.2/x86_64/baseos/os \
			-cert /rhel-certs/rhel-cert.pem \
			-key /rhel-certs/rhel-key.pem \
		> $(CRAWLED_PACKAGE_DIR)/rhel82-eus.txt

	# Crawl for Red Hat OpenShift Container Platform 4.3 for RHEL 8 x86_64 (rhocp-4.3-for-rhel-8-x86_64-rpms)
	docker run --rm \
		-v "$(BUILD_DATA_DIR)/rhel-certs:/rhel-certs:ro" \
		--entrypoint /usr/bin/rhel-crawler \
		kernel-crawler:latest \
			-base-url https://cdn.redhat.com/content/dist/layered/rhel8/x86_64/rhocp/4.3/os \
			-cert /rhel-certs/rhel-cert.pem \
			-key /rhel-certs/rhel-key.pem \
		> $(CRAWLED_PACKAGE_DIR)/rhel8-rhocp4.3.txt

	# Crawl for Red Hat OpenShift Container Platform 4.4 for RHEL 8 x86_64 (rhocp-4.4-for-rhel-8-x86_64-rpms)
	docker run --rm \
		-v "$(BUILD_DATA_DIR)/rhel-certs:/rhel-certs:ro" \
		--entrypoint /usr/bin/rhel-crawler \
		kernel-crawler:latest \
			-base-url https://cdn.redhat.com/content/dist/layered/rhel8/x86_64/rhocp/4.4/os \
			-cert /rhel-certs/rhel-cert.pem \
			-key /rhel-certs/rhel-key.pem \
		> $(CRAWLED_PACKAGE_DIR)/rhel8-rhocp4.4.txt

	## Crawl for Red Hat OpenShift Container Platform 4.5 for RHEL 8 x86_64 (rhocp-4.5-for-rhel-8-x86_64-rpms)
	docker run --rm \
		-v "$(BUILD_DATA_DIR)/rhel-certs:/rhel-certs:ro" \
		--entrypoint /usr/bin/rhel-crawler \
		kernel-crawler:latest \
			-base-url https://cdn.redhat.com/content/dist/layered/rhel8/x86_64/rhocp/4.5/os \
			-cert /rhel-certs/rhel-cert.pem \
			-key /rhel-certs/rhel-key.pem \
		> $(CRAWLED_PACKAGE_DIR)/rhel8-rhocp4.5.txt

.PHONY: crawl-docker-desktop
crawl-docker-desktop: build-crawl-container
	docker run --rm -i kernel-crawler crawl Docker-Desktop \
		> $(CRAWLED_PACKAGE_DIR)/docker-desktop-dmg.txt
	$(ROOT_DIR)/scripts/docker-desktop/crawl-kernel-images.sh \
		> $(CRAWLED_PACKAGE_DIR)/docker-desktop-kernel-layer.txt

.PHONY: filter-kernels-docker-desktop
filter-kernels-docker-desktop: build-crawl-container
	cat $(CRAWLED_PACKAGE_DIR)/docker-desktop-dmg.txt \
		$(CRAWLED_PACKAGE_DIR)/docker-desktop-kernel-layer.txt \
		| tr -c 'a-zA-Z0-9_.\n' '-' | awk -v prefix="/" '$$0=prefix$$0' \
		> /tmp/packages-docker-desktop.txt
	$(ROOT_DIR)/scripts/download-packages \
		$(BUILD_DATA_DIR) $(KERNEL_PACKAGE_BUCKET) /tmp/packages-docker-desktop.txt
	rm /tmp/packages-docker-desktop.txt
	docker run --rm -i \
		-e BUILD_DATA_DIR=/build-data \
		-v $(realpath $(BUILD_DATA_DIR)):/build-data \
		-v $(realpath $(CRAWLED_PACKAGE_DIR)):/kernel-package-lists \
		--entrypoint bash kernel-crawler docker-desktop-filter-kernels.sh \
			/kernel-package-lists/docker-desktop-dmg.txt \
			/kernel-package-lists/docker-desktop-kernel-layer.txt \
		> $(CRAWLED_PACKAGE_DIR)/docker-desktop.txt

.PHONY: crawl-fedora-coreos
crawl-fedora-coreos: build-crawl-container
	docker run --rm -i kernel-crawler crawl Fedora-CoreOS > $(CRAWLED_PACKAGE_DIR)/fedora-coreos.txt

.PHONY: crawl
crawl: build-crawl-container crawl-suse crawl-rhel crawl-centos crawl-kops crawl-amazon crawl-debian crawl-ubuntu-esm crawl-ubuntu-gcp crawl-ubuntu-hwe crawl-ubuntu-gke crawl-oracle-uek crawl-ubuntu-azure crawl-flatcar crawl-flatcar-beta crawl-gardenlinux crawl-ubuntu-aws crawl-docker-desktop crawl-fedora-coreos
	docker run --rm -i kernel-crawler crawl Container-OptimizedOS > $(CRAWLED_PACKAGE_DIR)/cos.txt
	docker run --rm -i kernel-crawler crawl Ubuntu > $(CRAWLED_PACKAGE_DIR)/ubuntu-standard.txt
	docker run --rm -i kernel-crawler crawl Minikube > $(CRAWLED_PACKAGE_DIR)/minikube.txt
