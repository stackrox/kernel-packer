[![CircleCI][circleci-badge]][circleci-link]
[![GCS Packages][gcs-packages-badge]][gcs-packages-link]
[![GCS Bundles][gcs-bundles-badge]][gcs-bundles-link]

# Kernel Packer

📦 Crawl and repackage kernel headers for collector

## Motivations and Goals

Kernel modules, and additionally eBPF modules, are the basis for how StackRox does runtime monitoring.

The production of kernel modules has historically been difficult, due to differences and inconsistencies in how various 
Linux distributions build their kernel modules.

This repository aims to define and abstract these processes away, so that downstream products can consume simplified and
homogeneous artifacts that can then be built upon. Additionally, this repository aims to fully automate the discovery 
and packaging of newly available kernel bundles. No human intervention should be necessary when upstream distros release
new kernel versions.

## Concepts

### Upstream

Linux distributions such as CoreOS, Debian, RedHat. & Ubuntu.

### Downstream

The [stackrox/collector](https://github.com/stackrox/collector) repository, specifically.

### Kernel Packages

A package file, typically a `.rpm`, or `.deb`, that is discovered from an upstream package repository by crawling. One 
or several different kernel packages are used in the production of one kernel bundle.

### Kernel Bundles

An artifact file produced from kernel packages. A bundle is a gzipped tarball with a `.tgz` extention. Consumed by 
downstream products.

### Crawling

Upstream kernel modules are distributed via a distribution's package repository. These package repositories are 
organized in a semi-standardized fashion, and can be programmatically scraped in order to discover the existence of new 
packages. Crawling is performed by the [`kernel-crawler`](kernel-crawler), and produces files inside of 
[`kernel-package-lists`](kernel-package-lists).

Crawling can be done by running `make crawl`. This is [done automatically](circleci/config.yml#L166), and shouldn't have
to be run manually.

### Manifest

After crawling, the set of discovered kernel packages are not in a very machine-consumable format. The generated 
[`manifest.yml`](kernel-package-lists/manifest.yml) YAML file is the source of truth for which sets of kernel packages 
to use for building a kernel bundle.

Generating the manifest can be done by running `make manifest`. This is done automatically, and shouldn't have to be run
manually.

## Kernel Bundles

Bundles are gzipped tarballs and around ~12MB each. They contain a file tree derived from a given distro's kernel header
packages. This file tree is usually a subset of the original packages, but is sufficient to compile modules against.

### Bundle Meta Files

Bundles contain a number of additional "meta" files that can be leveraged by bundle consumers. These files all exist at 
the root level of the tarball, and start with the `BUNDLE_` prefix.

| Filename             | Example          | Purpose                         |
| -------------------- | ---------------- | ------------------------------- |
| `./BUNDLE_BUILD_DIR` | `./build`        | Directory to run `make` from.   |
| `./BUNDLE_CHECKSUM`  | `02f...cd8`      | Build cache checksum.           |
| `./BUNDLE_DISTRO`    | `coreos`         | The type of Linux distribution. |
| `./BUNDLE_UNAME`     | `4.12.10-coreos` | The full kernel uname.          |
| `./BUNDLE_VERSION`   | `4`              | The kernel "version" component. |
| `./BUNDLE_MAJOR`     | `12`             | The kernel "major" component.   |
| `./BUNDLE_MINOR`     | `10`             | The kernel "minor" component.   |

All meta files contain a single value and are meant to be read like so:

```bash
uname="$(cat ./BUNDLE_UNAME)"
```

## Development

### Kernel Bundles
Kernel packages and kernel bundles are cached in `${source_root}/.build-data/`.  To generate all bundles locally, execute 
`make bundles` to build all bundles or `./script/local-bundle <kernel-version-regex>` to only build a subset of kernel bundles.
Building all bundles will take a long time and require downloading of several gigabytes of archived source packages. 
To test modifications to kernel bundle builder for a subset of kernel packages, create a manifest yaml file
containing only the subset and execute `MANIFEST_FILE={path to manifest.yml} make bundles`


[circleci-badge]:      https://circleci.com/gh/stackrox/kernel-packer.svg?&style=shield&circle-token=f65a92f3c16297b0433428aa9284803d1b649e72
[circleci-link]:       https://circleci.com/gh/stackrox/kernel-packer/tree/master
[gcs-bundles-badge]:   https://img.shields.io/badge/gcs-kernel%20bundles-blue.svg?style=flat&logo=google
[gcs-bundles-link]:    https://console.cloud.google.com/storage/browser/stackrox-kernel-bundles?project=stackrox-collector
[gcs-packages-badge]:  https://img.shields.io/badge/gcs-kernel%20packages-blue.svg?style=flat&logo=google
[gcs-packages-link]:   https://console.cloud.google.com/storage/browser/stackrox-kernel-packages?project=stackrox-collector
