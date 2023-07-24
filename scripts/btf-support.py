#!/usr/bin/env python3

import argparse
import os
import tarfile
import json


g_btf_info_config = b'CONFIG_DEBUG_INFO_BTF=y'


def has_btf_support(bundle):
    if not os.path.exists(bundle):
        return

    with tarfile.TarFile(bundle) as tar:
        try:
            config = tar.extractfile('./.config')
            return g_btf_info_config in config
        except KeyError:
            # config doesn't exist
            return False


def main():
    parser = argparse.ArgumentParser(description='Checks for BTF support in a given kernel bundle')
    parser.add_argument('bundle_dir', help='path to a directory containing the bundles')
    parser.add_argument('--output', help='path to the output json file')

    args = parser.parse_args()

    supports_btf = []

    for root, _, filenames in os.walk(args.bundle_dir):
        for fn in filenames:
            if not fn.endswith('tgz'):
                continue

            bundle, _ = os.path.splitext(fn)
            kernel = bundle[len('bundle-'):]

            if has_btf_support(os.path.join(root, fn)):
                print(f'{kernel} supports BTF')
                supports_btf.append(kernel)
            else:
                print(f'{kernel} does not support BTF')

    if args.output:
        with open(args.output, 'r') as input:
            content = json.load(input)

        existing_support = content.get('supports_btf', [])
        existing_support.extend(supports_btf)
        content['supports_btf'] = existing_support

        with open(args.output, 'w') as output:
            json.dump(content, output, indent=4)


if __name__ == '__main__':
    main()
