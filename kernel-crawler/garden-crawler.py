#!/usr/bin/env python3

import requests
import yaml
import re
import sys

image_version_re = re.compile(r'^linux-image-(((\d\.\d+)\.\d+-garden)(?:-cloud)?-amd64) (\d\.\d+\.\d+-0gardenlinux1)$')


def get_releases() -> dict:
    response = requests.get(
        'https://api.github.com/repos/gardenlinux/gardenlinux/releases')

    if not response.ok:
        sys.stderr.write(f'Failed to get tags for Garden Linux - {response.status_code}\n')
        return None

    return response.json()


def get_component_descriptors() -> list:
    """
    Searches the releases for a component descriptor in the assets section and
    returns a list of URLs where said descriptors can be downloaded from.
    """
    releases = get_releases()

    if releases is None:
        return

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
    kernel_versions = []

    for cd in component_descriptors:
        response = requests.get(cd)

        if not response.ok:
            sys.stderr.write(f'Failed to get component descriptors - {cd}\n')
            continue

        try:
            component = yaml.safe_load(response.text)
        except yaml.YAMLError as e:
            sys.stderr.write(f'Failed to load component descriptors - {cd}\n')
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

                    kernel_version = (release, debian_kernel, short_debian_kernel, garden_kernel)
                    if kernel_version not in kernel_versions:
                        kernel_versions.append(kernel_version)

                    break

    return kernel_versions


def print_package_urls(kernel_versions: list):
    for kv in kernel_versions:
        release, debian_kernel, short_debian_kernel, garden_kernel = kv

        print(f'http://repo.gardenlinux.io/gardenlinux/pool/main/l/linux-{release}/linux-headers-{short_debian_kernel}-common_{garden_kernel}_all.deb')
        print(f'http://repo.gardenlinux.io/gardenlinux/pool/main/l/linux-{release}/linux-headers-{debian_kernel}_{garden_kernel}_amd64.deb')
        print(f'http://repo.gardenlinux.io/gardenlinux/pool/main/l/linux-{release}/linux-kbuild-{release}_{garden_kernel}_amd64.deb')

def main():
    component_descriptors = get_component_descriptors()
    kernel_versions = get_kernel_versions(component_descriptors)
    print_package_urls(kernel_versions)


if __name__ == '__main__':
    main()
