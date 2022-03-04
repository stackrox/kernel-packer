#!/usr/bin/env python3

"""
This script is used to crawl Garden Linux releases and get the URLs for the
packages needed to build kernel modules, the logic goes a little like this:
- Query the github API to get the garden linux releases.
- Extract the download URL for the `component-descriptor`, a YAML file holding a
  description of packages used to build the release.
- Find the `linux-image` package from the `component-descriptor` and extract the
  kernel version numbers from it.
- Print the URLs holding the required packages to stdout.
"""

import requests
import yaml
import re
import sys

image_version_re = re.compile(
    r'^linux-image-(((\d\.\d+)\.\d+-garden)(?:-cloud)?-amd64) (\d\.\d+\.\d+-\d+gardenlinux\d+)$')


def get_releases() -> list:
    page = 1
    per_page = 30
    release_count = 30

    releases = []

    while release_count == per_page:
        params = {
            'page': page,
            'per_page': per_page
        }

        response = requests.get(
            'https://api.github.com/repos/gardenlinux/gardenlinux/releases', params=params)

        if not response.ok:
            sys.stderr.write(
                f'Failed to get tags for Garden Linux - {response.status_code}\n')
            return None

        response_page = response.json()
        releases += response_page

        release_count = len(response_page)
        page += 1

    return releases


def get_component_descriptors() -> list:
    """
    Searches the releases for a component descriptor in the assets section and
    returns a list of URLs where said descriptors can be downloaded from.
    """
    releases = get_releases()

    component_descriptors = []
    for release in releases:
        if 'assets' not in release:
            continue

        for asset in release['assets']:
            if asset['name'] != 'component-descriptor':
                continue

            sys.stderr.write(f'Considering release {release["tag_name"]}\n')
            component_descriptors.append(asset['browser_download_url'])
            break

    return component_descriptors


def get_kernel_versions(component_descriptors: list) -> list:
    """
    Uses a list of URLs to download `component-descriptors` that describe the
    build for a given Garden Linux release.

    From those files, a package starting with `linux-image` are used to get the
    kernel version information. A list of tuples containing the kernel
    information is returned.

    One of the returned tuples looks something a little like this:
    (
        release: 5.10
        debian_kernel: 5.10.100-garden-cloud-amd64
        short_debian_kernel: 5.10.100-garden
        garden_kernel: 5.10.100-0gardenlinux1
    )
    """
    kernel_versions = []

    for cd in component_descriptors:
        response = requests.get(cd)

        if not response.ok:
            sys.stderr.write(f'Failed to get component descriptors - {cd}\n')
            continue

        try:
            component = yaml.safe_load(response.text)
        except yaml.YAMLError as e:
            sys.stderr.write(f'Failed to load component descriptors - {cd}: {e}\n')
            continue

        for resource in component['component']['resources']:
            for label in resource['labels']:
                if label['name'] != 'gardener.cloud/gardenlinux/ci/build-metadata':
                    continue

                for pkg in label['value']['debianPackages']:
                    image = image_version_re.match(pkg)

                    if image is None:
                        continue

                    release = image[3]
                    debian_kernel = image[1]
                    short_debian_kernel = image[2]
                    garden_kernel = image[4]

                    kernel_version = (release, debian_kernel,
                                      short_debian_kernel, garden_kernel)
                    if kernel_version not in kernel_versions:
                        kernel_versions.append(kernel_version)

                    break

    return kernel_versions


def print_package_urls(kernel_versions: list):
    """
    Gets a list of tuples containing kernel information and prints a list with
    URLs for the packages needed to stdout. No duplicate URLs allowed.
    """
    base_url = 'http://repo.gardenlinux.io/gardenlinux/pool/main/l'

    urls = []
    for kv in kernel_versions:
        release, debian_kernel, short_debian_kernel, garden_kernel = kv

        url_all = f'{base_url}/linux-{release}/linux-headers-{short_debian_kernel}-common_{garden_kernel}_all.deb'
        url_amd64 = f'{base_url}/linux-{release}/linux-headers-{debian_kernel}_{garden_kernel}_amd64.deb'
        url_kbuild = f'{base_url}/linux-{release}/linux-kbuild-{release}_{garden_kernel}_amd64.deb'

        if url_all not in urls:
            urls.append(url_all)

        if url_amd64 not in urls:
            urls.append(url_amd64)

        if url_kbuild not in urls:
            urls.append(url_kbuild)

    print('\n'.join(urls))


def main():
    component_descriptors = get_component_descriptors()
    kernel_versions = get_kernel_versions(component_descriptors)
    print_package_urls(kernel_versions)


if __name__ == '__main__':
    main()
