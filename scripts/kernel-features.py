#!/usr/bin/env python3

import argparse
import os
import tarfile
import json
import sys


g_btf_info_config = b'CONFIG_DEBUG_INFO_BTF=y'
g_all_search_options = [
    g_btf_info_config
]


class Bundle:
    def __init__(self, path):
        self.path = path
        self.filename = os.path.basename(path)
        bundle, _ = os.path.splitext(self.filename)
        self.version = bundle[len('bundle-'):]

        self.btf = False

    def find_features(self):
        """
        Searches the bundle for all known features, first searching the config,
        and then in the wider bundle.
        """
        with tarfile.open(self.path) as tar:
            try:
                config = tar.extractfile('./.config')
                config = config.read()

                self.btf = g_btf_info_config in config
            except KeyError:
                found = self._search_bundle_for_features(tar, g_all_search_options)
                self.btf = found.get(g_btf_info_config, False)

        return self.to_dict()

    def to_dict(self):
        return {
            self.version: {
                'btf': self.btf
            }
        }

    def _search_bundle_for_features(self, tar, config_options):
        """
        Given a list of configuration options, this searches through all files
        in the bundle. This covers the case where the config does not exist
        (e.g. all the garden linux bundles)

        This is considered a worst case scenario, so the performance hit is
        rare.
        """
        results = {opt: False for opt in config_options}
        for item in tar.getnames():
            content = tar.extractfile(item)
            if not content:
                continue

            content = content.read()
            for option in list(config_options):
                if option in content:
                    results[option] = True
                    # we've found it, so remove it from future searches.
                    config_options.remove(option)

            if not config_options:
                break

        return results


def main():
    parser = argparse.ArgumentParser(description='Finds kernel features in a given kernel bundle')
    parser.add_argument('bundle_dir', help='path to a directory containing the bundles')
    parser.add_argument('--output', help='path to the output json file')

    args = parser.parse_args()

    kernels = []

    for fn in os.listdir(args.bundle_dir):
        _, ext = os.path.splitext(fn)

        if ext != '.tgz':
            continue

        bundle = Bundle(os.path.join(args.bundle_dir, fn))
        kernels.append(bundle.find_features())

    if args.output:
        try:
            with open(args.output, 'r') as input:
                content = json.load(input)
        except FileNotFoundError:
            content = []

        content.update(kernels)

        with open(args.output, 'w') as output:
            json.dump(content, output, indent=4)
    else:
        json.dump(kernels, sys.stdout, indent=4)


if __name__ == '__main__':
    main()
