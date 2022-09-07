# The below variables ontain a comma delimited list of GCP buckets,
# Scripts may read from all buckets but only write to the *first bucket* in the list.

KERNEL_PACKAGE_BUCKET="gs://stackrox-kernel-packages-staging/copy"
KERNEL_BUNDLE_BUCKET="gs://collector-kernel-bundles-public"

KERNEL_PACKAGE_STAGING_BUCKET="gs://stackrox-kernel-packages-staging/"
KERNEL_BUNDLE_STAGING_BUCKET="gs://stackrox-kernel-bundles-staging/"

if [[ "$BRANCH" =~ ^(master|main)$ ]]; then

    echo "Using production buckets"
    export KERNEL_PACKAGE_BUCKET="${KERNEL_PACKAGE_BUCKET}"
    export KERNEL_BUNDLE_BUCKET="${KERNEL_BUNDLE_BUCKET}"

else

    echo "Using staging buckets"
    export KERNEL_PACKAGE_BUCKET="${KERNEL_PACKAGE_STAGING_BUCKET},${KERNEL_PACKAGE_BUCKET}"
    export KERNEL_BUNDLE_BUCKET="${KERNEL_BUNDLE_STAGING_BUCKET},${KERNEL_BUNDLE_BUCKET}"

fi;

echo "KERNEL_BUNDLE_BUCKET=${KERNEL_BUNDLE_BUCKET}"
echo "KERNEL_PACKAGE_BUCKET=${KERNEL_PACKAGE_BUCKET}"
