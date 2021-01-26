#!/bin/bash

SUSE_REPO_URL="https://scc.suse.com/connect/organizations/repositories"

main() {
    tmp_dir="$(mktemp -d)"
    userpass="${SUSE_MIRRORING_USERNAME}:${SUSE_MIRRORING_PASSWORD}"

    # Fetch headers to determine the total number of pages for the repo data URL
    curl -s -I -u "${userpass}" "${SUSE_REPO_URL}"
    http_header_link="$(curl -s -I -u "${userpass}" "${SUSE_REPO_URL}" | grep "^link: .*$")"
    echo "${http_header_link}" | sed -E "s/.*page=([0-9]+)>; rel=\"last\".*/\\1/"
    last_page="$(echo "${http_header_link}" | sed -E "s/.*page=([0-9]+)>; rel=\"last\".*/\\1/")"

    # Get each repo page in json
    seq "${last_page}" | xargs -I{} -P4 -- curl -o "${tmp_dir}/repo_{}" -s -u "${userpass}" "${SUSE_REPO_URL}?page={}"

    # Join results, select x86_64 repos, and split out authorization token from the URL. Each url is of the form https://{URL}?{TOKEN}
    cat "${tmp_dir}"/repo_* | jq -s '[.[]] | flatten' | \
        jq '[.[] | select(.distro_target != null) | select(.distro_target | contains("x86_64"))]' | \
        jq 'map(.token = (.url | split("?")[1])) | map(.url |= split("?")[0]) | map({name,url,token})'
}

main "$@"
