#!/usr/bin/env bash
set -eou pipefail

rhel_package_lists=/tmp/rhel_package_lists.txt
ls /kernel-package-lists/rhel[0-9]*.txt > "$rhel_package_lists"

python crawler.py --rhelPackageLists "$rhel_package_lists"
