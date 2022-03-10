import os
import json
import requests
import re
import time
import logging
import argparse

logging.basicConfig()
logger = logging.getLogger('rhsm-crawler')
logger.setLevel("INFO")

# The swagger file for the RHSM API can be found here https://access.redhat.com/management/api/rhsm

class Crawler:
    def __init__(self, offline_token: str, get_latest: bool):
        self.offline_token = offline_token
        self.get_latest = get_latest
        self.api_url = 'https://api.access.redhat.com/management/v1'
        self.crawled_repos = set()
        self.non_empty_repos = set()
        self.subscriptions = set()
        self.non_empty_subscriptions = set()
        self.empty_subscriptions = set()
        self.allowed_pkg_names = ['kernel-devel', 'kernel-default-devel', 'kernel-rt-devel']

        self.repo_exclude_patterns = [
            re.compile(r'^.*-devtools-.*$'),
            re.compile(r'^.*-debug-.*$'),
            re.compile(r'^.*-source-.*$'),
            re.compile(r'^.*-beta-.*$'),
            re.compile(r'^.*-isos$'),
            re.compile(r'^codeready-builder-.*$')
        ]

        self.repo_include_patterns = [
            re.compile(r'^rhel-[7-8].*$'),
            re.compile(r'^rhel-server.*$'),
            re.compile(r'^rhocp-4.*$'),
            re.compile(r'^.*-rt-.*$')
        ]

        self.subscription_include_patterns = [
                re.compile(r'^Red Hat Enterprise Linux Developer Suite$'),
                re.compile(r'^Employee SKU$'),
                re.compile(r'^Red Hat OpenShift Container Platform, Premium \(16 Cores or 32 vCPUs\)$'),
                re.compile(r'^Red Hat Beta Access$'),
                re.compile(r'^Instructor SKU for Red Hat Training product downloads$'),
                re.compile(r'^RHUI Employee Subscription$'),
                re.compile(r'^Red Hat OpenShift Container Platform for NFV Edge Applications, Premium \(1 Socket\)$')
        ]

        self.exclude_checksums = [
                "1fbe3627107116c100361de382e346fb6101d86eb38f8cd180878719d00d3b6d",
                "ec27233de9e8996ae020e08681a146ff6f27209822f4cc1ef9ed7b266caf6c38",
                "5d67e44148014bf525fbe92dedc88fa8374867946fcfddbd68932791ed6c3690",
                "6bc958891e55e4aeb42efcd0590cbe55071642c52f204b603e043a69959e0efc",
                "d022084b449ffb893a040dc49818100b9fca411509ceb7f00366a1fd816dda96",
                "ad21a20b2c86d65521ebd1e5f37fe5a22d4fd9ef18f4a479372f9b5492b50b76",
                "d24df0ce5a399bba08dd367e5aae4fe40b2b9f851805274020a5c98c3f2d5e1d",
                "2812af0e083a2d9c9c296fbb574d072a6804098be431e4a950cf0a5f196d7c5f",
                "1384afbdbc01db3b1321bd8fc53654e2b8042cbfdf91e7fda99dfc069a22f14f"
        ]

        self.repos = [
                "rhocp-4.7-for-rhel-8-x86_64-rpms",
                "rhel-7-server-aus-rpms",
                "rhel-7-server-rhui-beta-rpms",
                "rhocp-4.3-for-rhel-8-x86_64-rpms",
                "rhocp-4.5-for-rhel-8-x86_64-rpms",
                "rhel-server-ost-6-3-rpms",
                "rhel-7-server-e4s-rpms",
                "rhel-8-for-x86_64-baseos-rpms",
                "rhel-7-server-rpms",
                "rhel-7-server-eus-rpms",
                "rhel-8-for-x86_64-baseos-e4s-rpms",
                "rhel-8-for-x86_64-rt-tus-rpms",
                "rhel-8-for-x86_64-baseos-eus-rpms",
                "rhel-8-for-x86_64-rt-rpms",
        ]

        self.headers = self.get_headers(True)

    def query_url(self, endpoint: str):
        return f'{self.api_url}{endpoint}'

    def check_match_regex(self, patterns, name):
        for pattern in patterns:
            if pattern.match(name):
                return True

        return False

    def exclude_repo(self, repo):
        return self.check_match_regex(self.repo_exclude_patterns, repo)

    def include_repo(self, repo):
        return self.check_match_regex(self.repo_include_patterns, repo)

    def include_subscription(self, subscription):
        return self.check_match_regex(self.subscription_include_patterns, subscription)

    def check_exclude_checksum(self, url):
        for exclude_sum in self.exclude_checksums:
            if url.find(exclude_sum) > -1:
                return True

        return False

    def get_refresh_token(self) -> dict:
        url = 'https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token'
        data = {
            'grant_type': 'refresh_token',
            'client_id': 'rhsm-api',
            'refresh_token': f'{self.offline_token}'
        }

        r = requests.post(url, data=data, headers={
                          'accept': 'application/json'})
        r.raise_for_status()

        return r.json()

    def get_headers(self, refresh = False):
        if refresh:
            token = self.get_refresh_token()['access_token']

            self.headers = {
                'Authorization': f'Bearer {token}',
                'accept': 'application/json'
            }

        return self.headers

    def paginate_request(self, endpoint: str):
        limit = 100
        offset = 0
        count = 100

        while True:
            params = {
                'limit': limit,
                'offset': offset
            }
            resp = requests.get(self.query_url(endpoint),
                                headers=self.get_headers(), params=params)

            if resp.status_code == 429:
                logger.debug(f'Rate limit exceeded, wait and retry...')
                time.sleep(int(resp.headers['x-ratelimit-delay']))
                resp = requests.get(self.query_url(endpoint),
                                    headers=self.headers, params=params)
        
            if resp.status_code == 401:
                resp = requests.get(self.query_url(endpoint),
                                    headers=self.get_headers(True), params=params)

            if not resp.ok:
                logger.debug(resp)
                break

            response = resp.json()

            count = response['pagination']['count']
            offset += count
            
            if count == 0:
                break

            yield response['body']

    def get_subscriptions(self) -> list:
        for subscriptions in self.paginate_request('/subscriptions'):
            for subscription in subscriptions:
                yield subscription

    def get_content_sets(self, subscription: list):
        subscription_number = subscription['subscriptionNumber']
        logger.debug("subscription_number= " + subscription_number)
        yield from self.paginate_request(f'/subscriptions/{subscription_number}/contentSets')

    def filter_repos(self, content_sets):
        repos = []
        for content_set in content_sets:
            repo = content_set["label"]
            if repo in self.crawled_repos:
                logger.debug(f'Skipping duplicated repository - {repo}')
                continue

            if self.exclude_repo(repo) or not self.include_repo(repo):
                logger.debug(f'Skipping {repo}')
                continue

            if 'arch' not in content_set:
                logger.debug(f'No arch - Skipping {content_set}')
                continue

            if 'x86_64' not in content_set['arch']:
                logger.debug(f'Unwanted arch - Skipping {content_set}')
                continue

            repos.append(repo)

        return repos


    def get_packages(self, repos):
        urls = set()
        for repo in repos:
            logger.debug(f'################ {repo} ################')

            self.crawled_repos.add(repo)

            endpoint = f'/packages/cset/{repo}/arch/x86_64'
            if self.get_latest:
                endpoint += '?filter=latest'

            for packages in self.paginate_request(endpoint):
                repo_urls = self.filter_kernel_headers(packages)
                urls |= repo_urls

                # Crawling all repos is expensive so save the ones that actually have packages we are
                # interested in. Later we can just crawl those repos.
                if not len(repo_urls) == 0:
                    self.non_empty_repos.add(repo)

                if packages[-1]['name'] > "kernel-rt-devel":
                    break

        return urls

    def filter_kernel_headers(self, packages):
        urls = set()
        for pkg in packages:
            pkg_name = pkg['name'] 

            if not pkg_name in self.allowed_pkg_names:
                continue

            url = pkg['downloadHref']

            if self.check_exclude_checksum(url):
                continue

            urls.add(url)

            kernel = f'{pkg_name}-{pkg["version"]}-{pkg["release"]}.x86_64'
            logger.debug(kernel)

        return urls

    def sort_and_output(self, urls):
        # For consistency with what was done before, sort URLs based on their alphabetical order
        #  _after_ reversing each of them.
        sorted_urls = sorted(urls, key=lambda s: s[::-1])
        print("\n".join(sorted_urls))

    def print_non_empty_repos(self):
        logger.debug("Non empty repos")
        for repo in self.non_empty_repos:
            logger.debug(repo)

    def print_empty_repos(self):
        logger.debug("empty repos")
        for repo in self.crawled_repos:
            if not repo in self.non_empty_repos:
                logger.debug(repo)

    def crawl_all(self):
        urls = set()
        for subscription in self.get_subscriptions():
            nurl_before = len(urls)  
            for content_sets in self.get_content_sets(subscription):
                repos = self.filter_repos(content_sets)
                repo_urls = self.get_packages(repos)
                urls |= repo_urls
            nurl_after = len(urls)
            
            if nurl_before == nurl_after:
                logger.debug("empty subscription= " + subscription['subscriptionName'])
                self.empty_subscriptions.add(subscription['subscriptionName'])
            else:
                logger.debug("non empty subscription= " + subscription['subscriptionName'])
                self.non_empty_subscriptions.add(subscription['subscriptionName'])


        self.sort_and_output(list(urls))

        logger.debug("All subscriptions crawled")

        self.print_non_empty_repos()
        self.print_empty_repos()
        
    def crawl_repos(self):
        urls = self.get_packages(self.repos)
        self.sort_and_output(list(urls))

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Arguments for RHSM API crawler')
    parser.add_argument('--all', type=bool, default=False)
    parser.add_argument('--logLevel', type=str, default="INFO")
    parser.add_argument('--getLatest', type=bool, default=False) # TODO: Set default to True
    args = parser.parse_args()

    logger.setLevel(args.logLevel)
    get_latest = args.getLatest

    # Go to https://access.redhat.com/management/api to get a token
    # and supply it as an environment variable.
    token = os.getenv('RHSM_OFFLINE_TOKEN')

    crawler = Crawler(token, get_latest)

    if args.all:
        crawler.crawl_all()
    else:
        crawler.crawl_repos()

