package main

import (
	"bufio"
	"flag"
	"fmt"
	"io"
	"os"

	"github.com/pkg/errors"

	"github.com/stackrox/kernel-packer/tools/generate-manifest/reformatters"
)

func main() {
	if err := mainCmd(); err != nil {
		fmt.Fprintf(os.Stderr, "generate-manifest: %s\n", err.Error())
		os.Exit(1)
	}
}

func readPackages(r io.Reader) ([]string, error) {
	var pkgs []string
	sc := bufio.NewScanner(r)
	for sc.Scan() {
		pkgs = append(pkgs, sc.Text())
	}
	return pkgs, sc.Err()
}

func mainCmd() error {
	var (
		reformatterFlag = flag.String("reformatter", "", "Reformatter to use")
	)
	flag.Parse()

	reformatter, err := reformatters.Get(*reformatterFlag)
	if err != nil {
		return errors.Wrap(err, "loading reformatter")
	}

	urls, err := readPackages(os.Stdin)
	if err != nil {
		return errors.Wrap(err, "loading package URLs")
	}

	packageSets, err := reformatter(urls)
	if err != nil {
		return errors.Wrap(err, "reformatting")
	}

	for _, pkgSet := range packageSets {
		for _, pkg := range pkgSet {
			fmt.Println(pkg)
		}
		fmt.Println("---------------------------------")
	}
	return nil
}
