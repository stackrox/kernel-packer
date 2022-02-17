#!/usr/bin/env python3

#### LICENSING:
#### This file is derived from sysdig, in scripts/kernel-crawler.py.
#### Sysdig is licensed under the GNU General Public License v2.
#### This file is not distributed with StackRox code, and is only
#### used during compilation.
####
#### Original attribution notice:
# Author: Samuele Pilleri
# Date: August 17th, 2015
#### END LICENSING

import argparse
import json
import sys
import time
import urllib3
from urllib3.util import parse_url as url_unquote
from urllib.parse import urljoin, urlparse
from lxml import html
import traceback
import re
import os.path

http = urllib3.PoolManager()

XPATH_NAMESPACES = {
  "regex": "http://exslt.org/regular-expressions",
}

#
# This is the main configuration tree for easily analyze Linux repositories
# hunting packages. When adding repos or so be sure to respect the same data
# structure
#
centos_excludes = [
    "3.10.0-123", # 7.0.1406
    "3.10.0-229", # 7.1.1503
    "3.10.0-327", # 7.2.1511
]
ubuntu_excludes = [
    "5.10.0-13.14",  # excluding this kernel because only the `all` pkg is available, the `amd64` pkg is missing.
    "5.15.0-1001.3", # excluding this kernel because only the `all` pkg is available, the `amd64` pkg is missing.
]
ubuntu_backport_supported = [
    "16.04",
    "20.04"
]
ubuntu_backport_excludes = [
    f"\r~(?!{ '|'.join(re.escape(s) for s in ubuntu_backport_supported) })", "+", # Prevent duplicate backports from cluttering the list, execept for supported backports.
]
debian_excludes = [
    "3.2.0", "3.16.0" # legacy
]
debian_backport_excludes = [
    "bpo",
]
docker_desktop_excludes = [
    "49550",
    "46911",
    "48506",
    "49427",
    "45519",
    "48029",
]
minikube_excludes = [
    "kubernetes/minikube/archive/v0.35.0.tar.gz",
    "kubernetes/minikube/archive/v0.34.1.tar.gz",
    "kubernetes/minikube/archive/v0.34.0.tar.gz",
    "kubernetes/minikube/archive/v0.33.1.tar.gz",
    "kubernetes/minikube/archive/v0.33.0.tar.gz",
    "kubernetes/minikube/archive/v0.32.0.tar.gz",
    "kubernetes/minikube/archive/v0.31.0.tar.gz",
    "kubernetes/minikube/archive/v0.30.0.tar.gz",
    "kubernetes/minikube/archive/v0.29.0.tar.gz",
]
garden_excludes = [
    "5.4.0",
    "dbgsym",
]
repos = {
    "CentOS" : [
        {
            # This is the root path of the repository in which the script will
            # look for distros (HTML page)
            "root" : "https://mirrors.kernel.org/centos/",

            # This is the XPath + Regex (optional) for analyzing the `root`
            # page and discover possible distro versions. Use the regex if you
            # want to limit the version release.
            # Here, we want subpaths like /7.5.1804/. The path /7/ is always
            # an alias to the latest release, so there is no use crawling it.
            "discovery_pattern" : "/html/body//pre/a[regex:test(@href, '^7\..*$')]/@href",

            # Once we have found every version available, we need to know were
            # to go inside the tree to find packages we need (HTML pages)
            "subdirs" : [
                "os/x86_64/Packages/",
                "updates/x86_64/Packages/"
            ],

            # Finally, we need to inspect every page for packages we need.
            # Again, this is a XPath + Regex query so use the regex if you want
            # to limit the number of packages reported.
            "page_pattern" : "/html/body//a[regex:test(@href, '^kernel-devel-?[0-9].*\.rpm$')]/@href",

            # Exclude old versions we choose not to support.
            "exclude_patterns": centos_excludes
        },

        {
            # This is the root path of the repository in which the script will
            # look for distros (HTML page)
            "root" : "https://mirrors.kernel.org/centos/",

            # This is the XPath + Regex (optional) for analyzing the `root`
            # page and discover possible distro versions. Use the regex if you
            # want to limit the version release.
            # Here, we want subpaths like /8.0.1905/, /8-stream/. The path /8/ is always
            # an alias to the latest release, so there is no use crawling it.
            "discovery_pattern" : "/html/body//pre/a[regex:test(@href, '^8[.-].*$')]/@href",

            # Once we have found every version available, we need to know were
            # to go inside the tree to find packages we need (HTML pages)
            "subdirs" : [
                "BaseOS/x86_64/os/Packages/",
            ],

            # Finally, we need to inspect every page for packages we need.
            # Again, this is a XPath + Regex query so use the regex if you want
            # to limit the number of packages reported.
            "page_pattern" : "/html/body//a[regex:test(@href, '^kernel-devel-?[0-9].*\.rpm$')]/@href",
        },

        {
            # CentOS Vault hosts packages that are no longer available on
            # the up-to-date mirrors.
            # Sysdig also crawls http://vault.centos.org/centos/, but that
            # appears to be completely redundant.
            "root" : "http://vault.centos.org/",
            # Here, we want subpaths like /7.5.1804/. The path /7/ is always
            # an alias to the latest release, so there is no use crawling it.
            "discovery_pattern" : "//body//table/tr/td/a[regex:test(@href, '^7\..*$')]/@href",

            "subdirs" : [
                "os/x86_64/Packages/",
                "updates/x86_64/Packages/"
            ],
            "page_pattern" : "//body//table/tr/td/a[regex:test(@href, '^kernel-devel-?[0-9].*\.rpm$')]/@href",
            "exclude_patterns": centos_excludes
        },

        # RHEL 7 kernel security update kernel-devel-3.10.0-1062.el7.x86_64.rpm)
        {
            "root" : "https://buildlogs.centos.org/c7.1908.00.x86_64/kernel/20190808101829/",
            "discovery_pattern" : "//body//table/tr/td/a[regex:test(@href, '^.*x86\_64/')]/@href",
            "subdirs" : [
                "",
            ],
            "page_pattern" : "//body//table/tr/td/a[regex:test(@href, '^kernel-devel-?[0-9].*\.rpm$')]/@href",
            "exclude_patterns": centos_excludes
        },

        {
            # All kernels released to the main ELRepo repo also end up in the
            # archive, so it's OK just to crawl the archive.
            # However, archives do eventually drop packages; track those in
            # centos-uncrawled.txt.
            "root" : "http://linux-mirrors.fnal.gov/linux/elrepo/archive/kernel/",
            "discovery_pattern" : "//body//table/tr/td/a[regex:test(@href, '^el7.*$')]/@href",
            "subdirs" : [
                "x86_64/RPMS/"
            ],
            "page_pattern" : "//body//table/tr/td/a[regex:test(@href, '^kernel-lt-devel-?[0-9].*\.rpm$')]/@href"
        },

        {
            "root" : "https://buildlogs.centos.org/centos/7/virt/",
            "discovery_pattern" : "//body//table//tr/td/a[regex:test(@href, '^x86_64.*$')]/@href",
            "subdirs" : [
                "xen/"
            ],
            "page_pattern" : "//body//table/tr/td/a[regex:test(@href, '^kernel-devel-?[0-9].*\.rpm$')]/@href"
        }
    ],

    ## As of September 22, 2020, CoreOS Container Linux release artifacts are no longer available (https://coreos.com/os/eol/)
    #"CoreOS" : [
    #    # {
    #    #     "root" : "http://alpha.release.core-os.net/",
    #    #     "discovery_pattern": "/html/body//a[regex:test(@href, 'amd64-usr')]/@href",
    #    #     "subdirs" : [
    #    #         ""
    #    #     ],
    #    #     "page_pattern" : "/html/body//a[regex:test(@href, '^[5-9][0-9][0-9]|current|[1][0-9]{3}')]/@href"
    #    # Note: ^[5-9][0-9][0-9] is excluded because versions under 1000 are so old.
    #    # },

    #    # {
    #    #     "root" : "http://beta.release.core-os.net/",
    #    #     "discovery_pattern": "/html/body//a[regex:test(@href, 'amd64-usr')]/@href",
    #    #     "subdirs" : [
    #    #         ""
    #    #     ],
    #    #     "page_pattern" : "/html/body//a[regex:test(@href, '^[1][0-9]{3}')]/@href"
    #    #     # Note: ^[5-9][0-9][0-9] is excluded because versions under 1000 are so old.
    #    # },

    #    {
    #        "root" : "http://stable.release.core-os.net/amd64-usr/",
    #        "discovery_pattern": "/html/body//a[regex:test(@href, '^2|1185|1[2-9][0-9]{2}')]/@href",
    #        # Note: ^[4-9][0-9][0-9] is excluded because versions under 1000 are so old.
    #        "subdirs" : [
    #            ""
    #        ],
    #        "page_pattern" : "/html/body//a[regex:test(@href, '^coreos_developer_container.bin.bz2$')]/@href"
    #    }
    #],

    "Flatcar": [
        {
            "root": "https://stable.release.flatcar-linux.net/amd64-usr/",
            "discovery_pattern": "/html/body//a[regex:test(@href, '^(\./)?[2-9]')]/@href",
            # Note: versions before 2000 are excluded because they are more than a year old at the time
            # we first see flatcar being used.
            "subdirs": [""],
            "page_pattern": "/html/body//a[regex:test(@href, '^(\./)?flatcar_developer_container.bin.bz2$')]/@href",
        },
    ],
    "Flatcar-Beta": [
        {
            "root": "https://beta.release.flatcar-linux.net/amd64-usr/",
            "discovery_pattern": r"/html/body//a[regex:test(@href, '^(\./)?(2513\.2\.0|2[6-9]|[3-9])')]/@href",
            "subdirs": [""],
            "page_pattern": "/html/body//a[regex:test(@href, '^(\./)?flatcar_developer_container.bin.bz2$')]/@href",
        },
    ],
    "Debian": [
        {
            "root": "http://security.debian.org/pool/updates/main/l/",
            "discovery_pattern": "/html/body//a[regex:test(@href, '^linux/')]/@href",
            "subdirs": [""],
            "page_pattern": "/html/body//a[regex:test(@href, '^linux-headers-[4-9].[0-9.]+-[^-]+-(?:cloud-)?(?:amd64|common_).*(?:amd64|all).deb$')]/@href",
            "exclude_patterns": debian_excludes,
        },
        {
            "root": "http://security.debian.org/pool/updates/main/l/",
            "discovery_pattern": "/html/body//a[regex:test(@href, '^linux/')]/@href",
            "subdirs": [""],
            "page_pattern": "/html/body//a[regex:test(@href, '^linux-kbuild-[4-9]\..*_amd64\.deb$')]/@href",
            "exclude_patterns": debian_excludes,
        },
        {
            "root": "http://debian.csail.mit.edu/debian/pool/main/l/",
            "discovery_pattern": "/html/body//a[regex:test(@href, '^linux/')]/@href",
            "subdirs": [""],
            "page_pattern": "/html/body//a[regex:test(@href, '^linux-headers-[4-9].[0-9.]+-[^-]+-(?:cloud-)?(?:amd64|common_).*(?:amd64|all).deb$')]/@href",
            "exclude_patterns": debian_excludes + debian_backport_excludes,
        },
        {
            "root": "http://debian.csail.mit.edu/debian/pool/main/l/",
            "discovery_pattern": "/html/body//a[regex:test(@href, '^linux/')]/@href",
            "subdirs": [""],
            "page_pattern": "/html/body//a[regex:test(@href, '^linux-kbuild-[4-9]\..*_amd64\.deb$')]/@href",
            "exclude_patterns": debian_excludes + debian_backport_excludes,
        },
    ],
    "Docker-Desktop": [
        {
            "root": "https://docs.docker.com/desktop/mac/release-notes/",
            "download_root": "",
            "discovery_pattern": "",
            "page_pattern": "/html/body//a[regex:test(@href, '^https://desktop.docker.com/mac/main/(?!arm64).*/Docker.dmg.*$')]/@href",
            "subdirs": [""],
            "exclude_patterns": docker_desktop_excludes,
        },
        {
            "root": "https://docs.docker.com/desktop/mac/release-notes/3.x/",
            "download_root": "",
            "discovery_pattern": "",
            "page_pattern": "/html/body//a[regex:test(@href, '^https://desktop.docker.com/mac/stable/(?!arm64).*/Docker.dmg.*$')]/@href",
            "subdirs": [""],
            "exclude_patterns": docker_desktop_excludes,
        },
    ],
    "Container-OptimizedOS": [
        {
            "type": "s3",
            "root": "https://storage.googleapis.com/cos-tools",
            "patterns": [
                "\d+\.\d+\.\d+/kernel-src.tar.gz$",
                "\d+\.\d+\.\d+/kernel-headers\.t(ar\.)?gz$",
            ]
        },
    ],

    "Minikube": [
        {
            "root": "https://github.com/kubernetes/minikube/releases",
            "download_root": "https://github.com",
            "discovery_pattern" : "",
            "subdirs": [""],
            "page_pattern" : "/html/body//a[regex:test(@href, '^/kubernetes/minikube/archive/refs/tags/v[0-9]+.[0-9]+.[0-9]+.tar.gz')]/@href",
            "exclude_patterns": minikube_excludes,
        },
    ],

    "Ubuntu": [
        # Generic Linux AMD64 headers, distributed from main
        {
            "root" : "http://security.ubuntu.com/ubuntu/pool/main/l/",
            "discovery_pattern" : "/html/body//a[@href = 'linux/']/@href",
            "subdirs" : [""],
            "page_pattern" : "/html/body//a[regex:test(@href, '^linux-headers-[4-9].*-generic.*amd64.deb$')]/@href",
            "exclude_patterns": ubuntu_excludes + ubuntu_backport_excludes,
        },

        # Generic Linux "all" headers, distributed from main
        {
            "root" : "http://security.ubuntu.com/ubuntu/pool/main/l/",
            "discovery_pattern" : "/html/body//a[@href = 'linux/']/@href",
            "subdirs" : [""],
            "page_pattern" : "/html/body//a[regex:test(@href, '^linux-headers-[4-9].*_all.deb$')]/@href",
            "exclude_patterns": ubuntu_excludes + ubuntu_backport_excludes,
        },
    ],

    "Ubuntu-HWE": [
        # Generic Linux AMD64 headers, distributed from main (HWE)
        {
            "root" : "http://security.ubuntu.com/ubuntu/pool/main/l/",
            "discovery_pattern" : "/html/body//a[@href = 'linux-hwe-edge/']/@href",
            "subdirs" : [""],
            "page_pattern" : "/html/body//a[regex:test(@href, '^linux-headers-[4-9].*-generic.*amd64.deb$')]/@href",
            "exclude_patterns": ubuntu_excludes,
            "include_patterns": ["4.15.0-15"],
        },

        # Generic Linux "all" headers, distributed from main (HWE)
        {
            "root" : "http://security.ubuntu.com/ubuntu/pool/main/l/",
            "discovery_pattern" : "/html/body//a[@href = 'linux-hwe-edge/']/@href",
            "subdirs" : [""],
            "page_pattern" : "/html/body//a[regex:test(@href, '^linux-headers-[4-9].*_all.deb$')]/@href",
            "exclude_patterns": ubuntu_excludes,
            "include_patterns": ["4.15.0-15"],
        },
    ],

    "Ubuntu-Azure": [
        # linux-azure AMD64 headers, distributed from main
        {
            "root" : "http://security.ubuntu.com/ubuntu/pool/main/l/",
            "discovery_pattern" : "/html/body//a[regex:test(@href, '^linux-azure(-.*)?/')]/@href",
            "subdirs" : [""],
            "page_pattern" : "/html/body//a[regex:test(@href, '^linux-headers-[4-9].*-azure.*amd64\.deb$')]/@href",
            "exclude_patterns": ubuntu_excludes + ubuntu_backport_excludes,
        },

        # linux-azure "all" headers, distributed from main
        {
            "root" : "http://security.ubuntu.com/ubuntu/pool/main/l/",
            "discovery_pattern" : "/html/body//a[regex:test(@href, '^linux-azure(-.*)?/')]/@href",
            "subdirs" : [""],
            "page_pattern" : "/html/body//a[regex:test(@href, '^linux-azure(-.*)?-headers-[4-9].*_all\.deb$')]/@href",
            "exclude_patterns": ubuntu_excludes + ubuntu_backport_excludes,
        },

        # Special case for Ubuntu Azure kernel 4.18, that only exists as a backport.
        # linux-azure 4.18 backports AMD64 headers, distributed from main
        {
            "root" : "http://security.ubuntu.com/ubuntu/pool/main/l/",
            "discovery_pattern" : "/html/body//a[@href = 'linux-azure/']/@href",
            "subdirs" : [""],
            "page_pattern" : "/html/body//a[regex:test(@href, '^linux-headers-4\.18[-.0-9]+azure_4\.18[-.0-9]+~.*amd64.deb$')]/@href",
            "exclude_patterns": ubuntu_excludes,
        },

        # linux-azure 4.18 backports "all" headers, distributed from main
        {
            "root" : "http://security.ubuntu.com/ubuntu/pool/main/l/",
            "discovery_pattern" : "/html/body//a[@href = 'linux-azure/']/@href",
            "subdirs" : [""],
            "page_pattern" : "/html/body//a[regex:test(@href, '^linux-azure-headers-4\.18[-.0-9]+_4\.18[-.0-9]+~.*_all.deb$')]/@href",
            "exclude_patterns": ubuntu_excludes,
        },
    ],

    "Ubuntu-AWS": [
        # linux-aws AMD64 headers, distributed from universe (older versions only)
        {
            "root" : "http://security.ubuntu.com/ubuntu/pool/universe/l/",
            "discovery_pattern" : "/html/body//a[@href = 'linux-aws/']/@href",
            "subdirs" : [""],
            "page_pattern" : "/html/body//a[regex:test(@href, '^linux-headers-[4-9].*-aws.*amd64.deb$')]/@href",
            "exclude_patterns": ubuntu_excludes
        },

        # linux-aws "all" headers, distributed from universe (older versions only)
        {
            "root" : "http://security.ubuntu.com/ubuntu/pool/universe/l/",
            "discovery_pattern" : "/html/body//a[@href = 'linux-aws/']/@href",
            "subdirs" : [""],
            "page_pattern" : "/html/body//a[regex:test(@href, '^linux-aws-headers-[4-9].*_all.deb$')]/@href",
            "exclude_patterns": ubuntu_excludes
        },

        # linux-aws AMD64 headers, distributed from main (newer versions only)
        {
            "root" : "http://security.ubuntu.com/ubuntu/pool/main/l/",
            "discovery_pattern" : "/html/body//a[regex:test(@href, '^linux-aws(-.*)?/$')]/@href",
            "subdirs" : [""],
            "page_pattern" : "/html/body//a[regex:test(@href, '^linux-headers-[4-9].*-aws.*amd64.deb$')]/@href",
            "exclude_patterns": ubuntu_excludes + ubuntu_backport_excludes,
        },

        # linux-aws "all" headers, distributed from main (newer versions only)
        {
            "root" : "http://security.ubuntu.com/ubuntu/pool/main/l/",
            "discovery_pattern" : "/html/body//a[regex:test(@href, '^linux-aws(-.*)?/$')]/@href",
            "subdirs" : [""],
            "page_pattern" : "/html/body//a[regex:test(@href, '^linux-aws(-.*)?-headers-[4-9].*_all.deb$')]/@href",
            "exclude_patterns": ubuntu_excludes + ubuntu_backport_excludes,
        }
    ],
    "Ubuntu-GCP": [
        # linux-gcp AMD64 headers, distributed from main
        {
            "root" : "http://security.ubuntu.com/ubuntu/pool/main/l/",
            "discovery_pattern" : "/html/body//a[regex:test(@href, '^linux-gcp(-.*)?/$')]/@href",
            "subdirs" : [""],
            "page_pattern" : "/html/body//a[regex:test(@href, '^linux-headers-[4-9].*-gcp.*amd64.deb$')]/@href",
            "exclude_patterns": ubuntu_excludes + ubuntu_backport_excludes
        },

        # linux-gcp "all" or amd64 headers, distributed from main.
        # Only amd64 packages have been published for recent kernel versions.
        {
            "root" : "http://security.ubuntu.com/ubuntu/pool/main/l/",
            "discovery_pattern" : "/html/body//a[regex:test(@href, '^linux-gcp(-.*)?/$')]/@href",
            "subdirs" : [""],
            "page_pattern" : "/html/body//a[regex:test(@href, '^linux-gcp(-.*)?-headers-[4-9].*_(all|amd64).deb$')]/@href",
            "exclude_patterns": ubuntu_excludes + ubuntu_backport_excludes
        },

        # linux-gcp AMD64 headers, distributed from universe
        {
            "root" : "http://security.ubuntu.com/ubuntu/pool/universe/l/",
            "discovery_pattern" : "/html/body//a[regex:test(@href, '^linux-gcp(-.*)?/$')]/@href",
            "subdirs" : [""],
            "page_pattern" : "/html/body//a[regex:test(@href, '^linux-headers-[4-9].*-gcp.*amd64.deb$')]/@href",
            "exclude_patterns": ubuntu_excludes + ubuntu_backport_excludes
        },

        # linux-gcp "all" headers, distributed from universe.
        # As of 4.15.0-1014, "all" is not uploaded, but "amd64" is.
        {
            "root" : "http://security.ubuntu.com/ubuntu/pool/universe/l/",
            "discovery_pattern" : "/html/body//a[regex:test(@href, '^linux-gcp(-.*)?/$')]/@href",
            "subdirs" : [""],
            "page_pattern" : "/html/body//a[regex:test(@href, '^linux-gcp(-.*)?-headers-[4-9].*_(all|amd64).deb$')]/@href",
            "exclude_patterns": ubuntu_excludes + ubuntu_backport_excludes
        },
    ],
    "Ubuntu-GKE": [
        # linux-gke AMD64 headers, distributed from main
        {
            "root" : "http://security.ubuntu.com/ubuntu/pool/main/l/",
            "discovery_pattern" : "/html/body//a[regex:test(@href, '^linux-gke(-.*)?/$')]/@href",
            "subdirs" : [""],
            "page_pattern" : "/html/body//a[regex:test(@href, '^linux-headers-[4-9].*-gke.*amd64.deb$')]/@href",
            "exclude_patterns": ubuntu_excludes,
        },

        # linux-gke "all" headers, distributed from main
        {
            "root" : "http://security.ubuntu.com/ubuntu/pool/main/l/",
            "discovery_pattern" : "/html/body//a[regex:test(@href, '^linux-gke(-.*)?/$')]/@href",
            "subdirs" : [""],
            "page_pattern" : "/html/body//a[regex:test(@href, '^linux-gke(-.*)?-headers-[4-9].*_(all|amd64).deb$')]/@href",
            "exclude_patterns": ubuntu_excludes,
        },

        # linux-gke AMD64 headers, distributed from universe
        {
            "root" : "http://security.ubuntu.com/ubuntu/pool/universe/l/",
            "discovery_pattern" : "/html/body//a[regex:test(@href, '^linux-gke(-.*)?/$')]/@href",
            "subdirs" : [""],
            "page_pattern" : "/html/body//a[regex:test(@href, '^linux-headers-[4-9].*-gke.*amd64.deb$')]/@href",
            "exclude_patterns": ubuntu_excludes
        },

        # linux-gke "all" headers, distributed from universe
        {
            "root" : "http://security.ubuntu.com/ubuntu/pool/universe/l/",
            "discovery_pattern" : "/html/body//a[regex:test(@href, '^linux-gke(-.*)?/$')]/@href",
            "subdirs" : [""],
            "page_pattern" : "/html/body//a[regex:test(@href, '^linux-gke(-.*)?-headers-[4-9].*_(all|amd64).deb$')]/@href",
            "exclude_patterns": ubuntu_excludes
        },

    ],
    "Ubuntu-ESM": [
        # Crawl Ubuntu 16.x Extended Security Maintainence backports, e.g. linux-headers-4.15.0-151-generic_4.15.0-151.157~16.04.1_amd64.deb.
        {
            "root" : "https://esm.ubuntu.com/infra/ubuntu/pool/main/l/",
            "discovery_pattern" : "/html/body//a[regex:test(@href, '^linux-(gcp|hwe|azure)(-.*)?/$')]/@href",
            "subdirs" : [""],
            "page_pattern" : "/html/body//a[regex:test(@href, '^linux-(gcp-|azure-)?headers-[4-9].*~16.[\.0-9]+_(all|amd64).deb$')]/@href",
            "exclude_patterns": ["lowlatency"],
            "http_request_headers" : urllib3.make_headers(basic_auth="bearer:"+os.getenv("UBUNTU_ESM_INFRA_BEARER_TOKEN",""))
        },
    ],
    "Ubuntu-FIPS": [
        # Crawl Ubuntu FIPS kernel headers
        {
            "root" : "https://esm.ubuntu.com/fips/ubuntu/pool/main/l/",
            "discovery_pattern" : "/html/body//a[regex:test(@href, '^linux(-gcp|-aws)?-fips/$')]/@href",
            "subdirs" : [""],
            "page_pattern" : "/html/body//a[regex:test(@href, '^linux-(gcp-|aws-)?(fips-)?headers-[4-9]\.[0-9]+\.[0-9]+-[0-9]+(-gcp|-aws)?(-fips)?_[4-9]\.[0-9]+\.[0-9]+-[0-9]+\.[0-9]+(_all|_amd64)?.deb$')]/@href",
            "exclude_patterns": ["lowlatency"],
            "http_request_headers" : urllib3.make_headers(basic_auth="bearer:"+os.getenv("UBUNTU_FIPS_BEARER_TOKEN",""))
        },
        # Crawl Ubuntu FIPS Updates kernel headers
        {
            "root" : "https://esm.ubuntu.com/fips-updates/ubuntu/pool/main/l/",
            "discovery_pattern" : "/html/body//a[regex:test(@href, '^linux(-gcp|-aws)?-fips/$')]/@href",
            "subdirs" : [""],
            "page_pattern" : "/html/body//a[regex:test(@href, '^linux-(gcp-|aws-)?(fips-)?headers-[4-9]\.[0-9]+\.[0-9]+-[0-9]+(-gcp|-aws)?(-fips)?_[4-9]\.[0-9]+\.[0-9]+-[0-9]+\.[0-9]+(_all|_amd64)?.deb$')]/@href",
            "exclude_patterns": ["lowlatency"],
            "http_request_headers" : urllib3.make_headers(basic_auth="bearer:"+os.getenv("UBUNTU_FIPS_UPDATES_BEARER_TOKEN",""))
        },
    ],

    "Oracle-UEK5": [
    	{
    		"root": "http://yum.oracle.com/repo/OracleLinux/OL7/developer_UEKR5/x86_64/",
    		"discovery_pattern": "",
    		"page_pattern": "/html/body//a[regex:test(@href, '^getPackage/kernel-uek-devel-[0-9].*\.x86_64\.rpm$')]/@href",
    		"subdirs": [""],
    	},
    ],
    "Fedora-CoreOS" : [
        {
            "root" : "https://kojipkgs.fedoraproject.org/packages/kernel/",
            "discovery_pattern": "/html/body//a[regex:test(@href, '^5\.(8|9|1[0-9])\..*/$')]/@href",
            "subdir_patterns": [
                "/html/body//a[regex:test(@href, '^[0-9]+\.fc[0-9]+/$')]/@href",
                "/html/body//a[regex:test(@href, '^x86_64/$')]/@href",
            ],
            "subdirs":  [""],
            "page_pattern" : "/html/body//a[regex:test(@href, '^kernel-devel-[0-9].*\.rpm$')]/@href",
         },
    ],
    "Garden-Linux" : [
        {
            "root": "http://45.86.152.1/gardenlinux/pool/main/l/",
            "discovery_pattern": "/html/body//a[regex:test(@href, '^linux/')]/@href",
            "subdirs": [""],
            "page_pattern": "/html/body//a[regex:test(@href, '^linux-headers-[4-9].[0-9.]+-[^-]+-(?:cloud-)?(?:amd64|common_).*(?:amd64|all).deb$')]/@href",
            "exclude_patterns": garden_excludes,
        },
        {
            "root": "http://45.86.152.1/gardenlinux/pool/main/l/",
            "discovery_pattern": "/html/body//a[regex:test(@href, '^linux/')]/@href",
            "subdirs": [""],
            "page_pattern": "/html/body//a[regex:test(@href, '^linux-kbuild-[4-9]\..*_amd64\.deb$')]/@href",
            "exclude_patterns": garden_excludes,
        }
    ]
}

def check_pattern(pattern, s):
    if len(pattern) > 1 and pattern[0:2] == "\r":
        return re.compile(pattern[2:]).match(s) != None
    return pattern in s

retry = urllib3.util.Retry(connect=5, read=5, redirect=5, backoff_factor=1)
timeout = urllib3.util.Timeout(connect=10, read=60)
http = urllib3.PoolManager(retries=retry, timeout=timeout)

def crawl_s3(repo):
    def val(xml, path):
        vals = xml.xpath(path)
        if len(vals) == 0:
            return ''
        if len(vals) == 1:
            return vals[0]
        raise "Expected only one value for path %r"%(path,)
    results = []
    read_more = True
    next_marker = None
    while read_more:
        url = repo['root']
        if next_marker:
            url += "?marker=" + next_marker
        body = http.request('GET', url, timeout=30.0, headers=repo.get("http_request_headers",{})).data
        xml = html.fromstring(body)
        read_more = val(xml, '//istruncated/text()').lower() == "true"
        next_marker = val(xml, '//nextmarker/text()')

        for key in xml.xpath('//contents/key/text()'):
            for pattern in repo['patterns']:
                if re.search(pattern, key):
                    result = "{}/{}".format(repo['root'], key)
                    results.append(result)
    results.sort()
    return results

def get_rpms(repo):
    max_tries = 6
    for i in range(max_tries):
        try:
            rpms = html.fromstring(page).xpath(repo["page_pattern"], namespaces=XPATH_NAMESPACES)
            return rpms
        except:
            sys.stderr.write("WARN: Unable to get repos. " + str(max_tries - i - 1)  + " tries left\n")
            time.sleep(120)

    return []


def crawl(distro):
    """
    Navigate the `repos` tree and look for packages we need that match the
    patterns given.
    """

    kernel_urls = []
    for repo in repos[distro]:
        sys.stderr.write("Considering repo " + repo["root"] + "\n")

        http_request_headers=repo.get("http_request_headers", {})
        if "type" in repo and repo["type"] == "s3":
            sys.stderr.write("Crawling S3 bucket\n")
            kernel_urls += crawl_s3(repo)
            continue

        try:
            root = http.request('GET', repo["root"], timeout=30.0, headers=http_request_headers).data
            versions = [""]
            if len(repo["discovery_pattern"]) > 0:
                versions = html.fromstring(root).xpath(repo["discovery_pattern"], namespaces=XPATH_NAMESPACES)
            if "subdir_patterns" in repo:
                versions = expand_versions_by_subdir_patterns(repo, versions)
            for version in sorted(set(versions)):
                sys.stderr.write("Considering version "+version+"\n")
                for subdir in sorted(set(repo["subdirs"])):
                    try:
                        sys.stderr.write("Considering version " + version + " subdir " + subdir + "\n")
                        source = repo["root"] + version + subdir
                        download_root = source if "download_root" not in repo else repo["download_root"]
                        page = http.request('GET', source, timeout=30.0, headers=http_request_headers).data
                        rpms = get_rpms(repo)
                        if len(rpms) == 0:
                            sys.stderr.write("WARN: Zero packages returned for version " + version + " subdir " + subdir + "\n")
                        for rpm in sorted(set(rpms)):
                            sys.stderr.write("Considering package " + rpm + "\n")
                            if "exclude_patterns" in repo and any(check_pattern(x,rpm) for x in repo["exclude_patterns"]):
                                continue
                            if "include_patterns" in repo and not any(check_pattern(x,rpm) for x in repo["include_patterns"]):
                                continue
                            else:
                                base_url = urljoin(rpm, urlparse(rpm).path)
                                raw_url = "{}{}".format(download_root, url_unquote(base_url))
                                sys.stderr.write("Adding package " + raw_url + "\n")
                                prefix, suffix = raw_url.split('://', maxsplit=1)
                                kernel_urls.append('://'.join((prefix, os.path.normpath(suffix))))
                    except urllib3.exceptions.HTTPError as e:
                        sys.stderr.write("WARN: Error for source: {}: {}\n".format(source, e))

        except Exception as e:
            sys.stderr.write("ERROR: "+str(type(e))+str(e)+"\n")
            traceback.print_exc()
            sys.exit(1)

    return kernel_urls


def read_kernel_urls_from_stdin():
    input_urls = []
    for line in sys.stdin:
        input_urls.append(line.strip())

    return input_urls


def sort_and_output(urls):
    # For consistency with what was done before, sort URLs based on their alphabetical order
    #  _after_ reversing each of them.
    sorted_urls = sorted(urls, key=lambda s: s[::-1])
    print("\n".join(sorted_urls))


def handle_crawl(args):
    crawled_urls = crawl(args.distro)
    if not args.preserve_removed_urls:
        sort_and_output(crawled_urls)
        return

    input_urls = read_kernel_urls_from_stdin()
    if len(input_urls) == 0:
        raise Exception("Preserve removed urls was selected, but we couldn't read any urls from stdin!")

    removed_urls = [url for url in input_urls if url not in set(crawled_urls)]
    urls_dict = {
        "removed": removed_urls,
        "crawled": crawled_urls,
    }
    print(json.dumps(urls_dict))


def handle_output_from_json(args):
    urls_dict = json.loads(sys.stdin.read())
    sort_and_output(urls_dict[args.mode])

def expand_versions_by_subdir_patterns(repo, versions):
    more = []
    for version in versions:
        more = more + descend_path(repo["root"], version, repo["subdir_patterns"])
    return more

def descend_path(root, path, patterns):
    copy = patterns[:]
    pattern = copy.pop(0)
    patterns = copy

    sys.stderr.write("Getting subdirs under " + path + " using pattern " + pattern + "\n")
    page = http.request('GET', root + path).data
    subdirs = html.fromstring(page).xpath(pattern, namespaces=XPATH_NAMESPACES)
    if len(subdirs) == 0:
        return []

    paths = list(map(lambda subdir: path + subdir, subdirs))

    if len(patterns) == 0:
        return paths

    more = []
    for path in paths:
        more = more + descend_path(root, path, patterns)

    return more

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Kernel module crawler.")

    subparsers = parser.add_subparsers()

    parser_crawl = subparsers.add_parser("crawl", help="Crawl modules")
    parser_crawl.add_argument("distro", choices=repos.keys(), help="The distro you want to crawl for.")
    parser_crawl.add_argument("--preserve-removed-urls", action="store_true",
                              help="Use this option to pass the old list of kernels via stdin, and get a JSON "
                                   "with both new kernels and old kernels")
    parser_crawl.set_defaults(func=handle_crawl)

    parser_output_from_json = subparsers.add_parser("output-from-json",
                                                    help="Output url files based on a stored JSON from a previous "
                                                         "invocation of crawl.")
    parser_output_from_json.add_argument(
        "mode", choices=["crawled", "removed"],
        help="Do you want to print the newly crawled files, or update the 'uncrawled' file?")
    parser_output_from_json.set_defaults(func=handle_output_from_json)

    args = parser.parse_args()
    args.func(args)
