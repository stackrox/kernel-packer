# SUSE kernel crawling

Crawling for SUSE kernels utilizes mirroring credentials from SUSE for the RMT mirroring server (https://github.com/SUSE/rmt)
Details on retrieval of these credentials can be found in the SUSE package mirroring [documentation](https://documentation.suse.com/sles/15-SP1/single-html/SLES-rmt/index.html#sec-rmt-mirroring-credentials).
The username and password used by kernel-packer is associated with the NFR license provided to StackRox by SUSE.

The script `./kernel-crawler/suse/get-repo-tokens.sh` uses the credentials stored as CircleCI environment variables, `SUSE_MIRRORING_USERNAME` and `SUSE_MIRRORING_PASSWORD`,
to download and generate a JSON file that contains a unique access token for every SUSE package repository.

The access tokens are stored in `.build-data/` and used to by the rhel-crawler
tool (`kernel-crawler/main.go`) to crawl the subset of SUSE repositories we
support (`kernel-crawler/suse/repo-names.txt`). The tokens are also used by `scripts/sync` to download
the kernel header packages.



