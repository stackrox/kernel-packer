### Artifacts created by CircleCI in GCS

During the most recent successful CircleCI run of this PR, files may have been
created (see below for details).  These artifacts are stored for testing or
inspection purposes.

The _crawl_ job downloaded and added `{{.Env.PACKAGE_COUNT}}` kernel header
package(s) to GCS storage.

{{if .Env.PACKAGE_COUNT}}
`KERNEL_PACKAGES_STAGING_BUCKET: {{.Env.KERNEL_PACKAGE_STAGING_BUCKET}}`
{{end}}


The _repackage_ job created `{{.Env.BUNDLE_COUNT}}` kernel header bundle(s)
in a staging directory in GCS storage.

{{if .Env.BUNDLE_COUNT}}
`KERNEL_BUNDLES_STAGING_BUCKET: {{.Env.KERNEL_BUNDLE_STAGING_BUCKET}}`
{{end}}


_Last updated: {{.Env.LAST_UPDATED}}_
