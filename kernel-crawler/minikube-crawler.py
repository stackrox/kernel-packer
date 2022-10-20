#! /usr/bin/env python3

# This crawler is loosely based on falco's crawler for minikube
# You can find it here:
# https://github.com/falcosecurity/kernel-crawler/blob/e2bbe6455ef26941e3f53f9f6481e7a610746484/kernel_crawler/minikube.py

import tempfile
import sys
import os
import re
import semver
import pygit2


def clone_repo():
    work_dir = tempfile.mkdtemp(prefix="minikube-")
    return pygit2.clone_repository("https://github.com/kubernetes/minikube.git", work_dir)


def filter_versions(version):
    if semver.compare('1.24.0', version) > 0:
        return False

    semver_version = semver.VersionInfo.parse(version)
    return semver_version.prerelease is None and semver_version.build is None


def get_versions(repo):
    re_tags = re.compile('^refs/tags/v(?P<major>0|[1-9]\d*)\.(?P<minor>0|[1-9]\d*)\.(?P<patch>0|[1-9]\d*)$')

    all_versions = [os.path.basename(v).strip('v') for v in repo.references if re_tags.match(v)]
    filtered_versions = list(filter(filter_versions, all_versions))

    return filtered_versions


def get_minikube_config_file_name(version):
    if semver.compare('1.26.0', version) <= 0:
        return 'minikube_x86_64_defconfig'
    return 'minikube_defconfig'


def get_kernel_config_file_name(version):
    if semver.compare('1.26.0', version) <= 0:
        return 'linux_x86_64_defconfig'
    return 'linux_defconfig'


def search_files(directory, file_name):
    for dirpath, dirnames, files in os.walk(directory, followlinks=True):
        for name in files:
            if name == file_name:
                return os.path.join(dirpath, name)
    return None


def get_kernel_release(repo, version):
    # here kernel release is the same as the one given by "uname -r"
    file_name = get_minikube_config_file_name(version)
    full_path = search_files(repo.workdir, file_name)
    for line in open(full_path):
        if re.search(r'^BR2_LINUX_KERNEL_CUSTOM_VERSION_VALUE=', line):
            tokens = line.strip().split('=')
            return full_path[len(repo.workdir):], tokens[1].strip('"')


def get_defconfig(repo, minikube_version):
    file_name = get_kernel_config_file_name(minikube_version)
    return search_files(repo.workdir, file_name)[len(repo.workdir):]


def print_config_files(kernel_data):
    for kd in kernel_data:
        print(f'https://raw.githubusercontent.com/kubernetes/minikube/{kd["version"]}/{kd["config"]}')
        print(f'https://raw.githubusercontent.com/kubernetes/minikube/{kd["version"]}/{kd["minikube"]}')


def print_kernel_packages(kernel_data):
    for kd in kernel_data:
        version = semver.VersionInfo.parse(kd['kernel'])
        print(f'https://cdn.kernel.org/pub/linux/kernel/v{version.major}.x/linux-{kd["kernel"]}.tar.xz')


def main():
    repo_handle = clone_repo()
    versions = get_versions(repo_handle)

    kernel_data = []
    for v in versions:
        repo_handle.checkout(f'refs/tags/v{v}')
        minikube_defconfig, kernel_release = get_kernel_release(repo_handle, v)
        kernel_config = get_defconfig(repo_handle, v)
        kernel_data.append({
            'kernel': kernel_release,
            'version': f'v{v}',
            'config': kernel_config,
            'minikube': minikube_defconfig,
        })

    print_config_files(kernel_data)
    print_kernel_packages(kernel_data)


if __name__ == '__main__':
    main()
