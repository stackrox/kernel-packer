#!/usr/bin/env bash

checkout_dir="$(mktemp -d)"

cleanup() {
  [[ -z "$checkout_dir" ]] || rm -rf "$checkout_dir" 2>/dev/null
}
trap cleanup INT TERM EXIT

git clone -q "https://github.com/gardenlinux/gardenlinux.git" "$checkout_dir"

while read -r sha || [[ -n "$sha" ]]; do
  PAGER="cat" git -C "$checkout_dir" show "${sha}:features/cloud/exec.config" |
    egrep -o 'https://snapshot.debian.org/[^[:space:]]+/linux-image-[[:digit:]][^[:space:]]+\.deb'
done < <(git -C "$checkout_dir" log --format='%H' -- features/cloud/exec.config) |
  sort | uniq |
  sed -E 's@^(https://.+)/linux-signed-amd64/linux-image-([[:digit:]]+\.[[:digit:]]+)(\.[[:digit:]]+-[[:digit:]]+)-cloud-amd64_([0-9.-]+)_amd64\.deb$@\1 \2 \3 \4@g' |
  awk '{
    print $1 "/linux/linux-headers-" $2 $3 "-common_" $4 "_all.deb" ;
    print $1 "/linux/linux-headers-" $2 $3 "-cloud-amd64_" $4 "_amd64.deb" ;
    print $1 "/linux/linux-kbuild-" $2 "_" $4 "_amd64.deb"
  }'
