module github.com/stackrox/kernel-packer

go 1.16

require (
	github.com/davecgh/go-spew v1.1.1 // indirect
	github.com/fatih/color v1.7.0
	github.com/mattn/go-colorable v0.0.9 // indirect
	github.com/mattn/go-isatty v0.0.4 // indirect
	github.com/pkg/errors v0.8.1
	github.com/stretchr/testify v1.3.0
	golang.org/x/sys v0.0.0-20190220154126-629670e5acc5 // indirect
	gopkg.in/yaml.v2 v2.4.0
)

replace gopkg.in/yaml.v2 v2.4.0 => github.com/joshdk/yaml v0.0.0-20190223191700-1da71b7c0e46
