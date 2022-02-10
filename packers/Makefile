.DEFAULT_GOAL = all

.PHONY: all
all:
	@DOCKER_BUILDKIT=1 docker build --build-arg REDHAT_USERNAME --secret id=REDHAT_PASSWORD -t repackage .
	@docker build -t repackage:debian -f Dockerfile.debian
