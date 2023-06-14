.DEFAULT_GOAL = all

.PHONY: all
all:
	@docker build -t repackage .
	@docker build -t repackage-bookworm -f Dockerfile.bookworm .
