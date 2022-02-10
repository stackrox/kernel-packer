.DEFAULT_GOAL = all

.PHONY: all
all: default debian

.PHONY: default
default:
	@DOCKER_BUILDKIT=1 docker build --build-arg REDHAT_USERNAME --secret id=REDHAT_PASSWORD -t repackage .

.PHONY: debian
debian:
	@docker build -t repackage:debian . -f Dockerfile.debian
