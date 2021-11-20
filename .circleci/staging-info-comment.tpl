### Artifacts created by CircleCI in GCS

During the most recent successful CircleCI run of this PR, files may have been
created (see below for details).  These artifacts are stored for testing or
inspection purposes.

The _crawl_ job downloaded and added `{{.Env.PACKAGE_COUNT}}` kernel header
package(s) to in GCS storage:

`KERNEL_PACKAGES_STAGING_BUCKET: {{.Env.KERNEL_PACKAGE_STAGING_BUCKET}}`


The _repackage_ job created `{{.Env.BUNDLE_COUNT}}` kernel header bundle(s) to
a staging directory in GCS storage:

`KERNEL_BUNDLES_STAGING_BUCKET: {{.Env.KERNEL_BUNDLE_STAGING_BUCKET}}`


_Last updated: {{.Env.LAST_UPDATED}}_
