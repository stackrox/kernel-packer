#!/bin/bash

# Generate a JSON containing SUSE repositories and the access token for each.
# The output is an array of JSON objects with the keys, 'name','url', and 'token'
# Each repository URL has a unique token and is used as a query parameter.
#
# See the RMT source code for more details:
# https://github.com/SUSE/rmt/blob/master/lib/suse/connect/api.rb#L108

SUSE_REPO_URL="https://scc.suse.com/connect/organizations/repositories"

main() {
    tmp_dir="$(mktemp -d)"
    userpass="${SUSE_MIRRORING_USERNAME}:${SUSE_MIRRORING_PASSWORD}"

    # Fetch headers to determine the total number of pages for the repo data URL
    http_header_link="$(curl -s -I -u "${userpass}" "${SUSE_REPO_URL}" | grep "^[Ll]ink: .*$")"
    last_page="$(echo "${http_header_link}" | sed -E "s/.*page=([0-9]+)>; rel=\"last\".*/\\1/")"

    # Get each repo page in json
    seq "${last_page}" | xargs -I{} -P4 -- curl -o "${tmp_dir}/repo_{}" -s -u "${userpass}" "${SUSE_REPO_URL}?page={}"

    # Join results, filter just x86_64 repos, and split out authorization token from the URL.
    # Each url is of the form https://{URL}?{TOKEN}
    cat "${tmp_dir}"/repo_* | jq -s '[.[]] | flatten' | \
        jq '[.[] | select(.distro_target != null) | select(.distro_target | contains("x86_64"))]' | \
        jq 'map(.token = (.url | split("?")[1])) | map(.url |= split("?")[0]) | map({name,url,token})'
}

main "$@"
