package reformatters

import (
	"fmt"
	"path"
	"regexp"
	"sort"
	"strconv"
	"strings"

	"github.com/pkg/errors"
)

var (
	reVersion = regexp.MustCompile(`(\d+\.\d+\.\d+-\d+)\.(\d+)`)

	reformatters = map[string]ReformatterFunc{
		"one-to-each":  reformatOneToEach,
		"one-to-pairs": reformatOneToPairs,
		"pairs":        reformatPairs,
		"single":       reformatSingle,
		"debian":       reformatDebian,
	}
)

type ReformatterFunc func(packages []string) ([][]string, error)

// Get returns the given reformatter by name, or an error if it does not exist.
func Get(name string) (ReformatterFunc, error) {
	reformatter, found := reformatters[name]
	if !found {
		return nil, errors.New("unknown reformatter")
	}
	return reformatter, nil
}

// reformatOneToEach consumes a list of packages, and returns a list of package
// groups. Each package group is comprised of the first package listed, and is
// paired with every package in turn.
//
// For example:
// [a, b, c] → [[a, b], [a, c]]
func reformatOneToEach(packages []string) ([][]string, error) {
	var (
		sets  = make([][]string, 0, len(packages))
		first = packages[0]
	)

	for _, pkg := range packages[1:] {
		set := []string{first, pkg}
		sets = append(sets, set)
	}

	return sets, nil
}

// reformatOneToPairs consumes a list of packages, and returns a list of
// package groups. Each package group is comprised of the first package listed,
// and a triple is made with every pair of packages in turn.
//
// For example:
// [a, b, c, d, e] → [[a, b, c], [a, d, e]]
func reformatOneToPairs(packages []string) ([][]string, error) {
	if len(packages) < 3 || len(packages)%2 == 0 {
		panic("bad package count")
	}
	var (
		sets  = make([][]string, 0, len(packages))
		first = packages[0]
	)

	for index := 1; index < len(packages); index += 2 {
		set := []string{first, packages[index], packages[index+1]}
		sets = append(sets, set)
	}

	return sets, nil
}

var (
	debianKBuildVersionRegex = regexp.MustCompile(`^linux-kbuild-(\d+(?:\.\d+)*)_([^_]+)(?:_.*)?\.deb$`)
	debianHeaderVersionRegex = regexp.MustCompile(`^linux-headers-(\d+(?:\.\d+)*-\d+)-[^_]+_([^_]+)(?:_.*)?\.deb$`)
	versionSepRegex          = regexp.MustCompile(`[-.]`)
	packagePoolRegex         = regexp.MustCompile(`^https?://([^.]*).debian.org/.*/.*\.deb$`)
	debianSecurityURL        = "security.debian.org"
)

type packageInfo struct {
	kernelVersion, packageVersion string
	name, url                     string
}

func equalPackagePool(urlA, urlB string) bool {
	urlAMatches := packagePoolRegex.FindStringSubmatch(urlA)
	urlBMatches := packagePoolRegex.FindStringSubmatch(urlB)
	if len(urlAMatches) != 2 || len(urlBMatches) != 2 {
		return false
	}
	return urlAMatches[1] == urlBMatches[1]
}

func reformatDebian(packages []string) ([][]string, error) {
	if len(packages) < 3 {
		return nil, errors.New("bad package count")
	}

	kbuildsByKernelVersion := make(map[string][]packageInfo)
	kbuildsByPackageVersion := make(map[string]packageInfo)
	headersByKernelVersion := make(map[string][]packageInfo)
	headersByPackageName := make(map[string]packageInfo)

	for _, pkg := range packages {
		name := path.Base(pkg)
		matches := debianKBuildVersionRegex.FindStringSubmatch(name)
		if len(matches) < 3 {
			continue
		}
		pkgInfo := packageInfo{
			url:            pkg,
			name:           name,
			kernelVersion:  matches[1],
			packageVersion: matches[2],
		}

		if existingPkg := kbuildsByPackageVersion[pkgInfo.packageVersion]; existingPkg.url != "" {
			return nil, errors.Errorf("file clash for kbuild package for package version %s: %s, %s", pkgInfo.packageVersion, existingPkg.url, pkg)
		}
		kbuildsByPackageVersion[pkgInfo.packageVersion] = pkgInfo

		kbuildsByKernelVersion[pkgInfo.kernelVersion] = append(kbuildsByKernelVersion[pkgInfo.kernelVersion], pkgInfo)
	}

	for _, pkgInfos := range kbuildsByKernelVersion {
		sort.Slice(pkgInfos, func(i, j int) bool {
			return versionLess(pkgInfos[j].packageVersion, pkgInfos[i].packageVersion)
		})
	}

	for _, pkg := range packages {
		name := path.Base(pkg)
		matches := debianHeaderVersionRegex.FindStringSubmatch(name)
		if len(matches) < 3 {
			continue
		}
		pkgInfo := packageInfo{
			url:            pkg,
			name:           name,
			kernelVersion:  matches[1],
			packageVersion: matches[2],
		}
		// prefer security.debian.org for duplicates
		if existingPkg := headersByPackageName[pkgInfo.name]; !strings.Contains(existingPkg.url, debianSecurityURL) {
			headersByPackageName[pkgInfo.name] = pkgInfo
		}
	}

	for _, pkgInfo := range headersByPackageName {
		headersByKernelVersion[pkgInfo.kernelVersion] = append(headersByKernelVersion[pkgInfo.kernelVersion], pkgInfo)
	}

	for _, pkgInfos := range headersByKernelVersion {
		sort.Slice(pkgInfos, func(i, j int) bool {
			return versionLess(pkgInfos[j].packageVersion, pkgInfos[i].packageVersion)
		})
	}

	headers := make(map[string][]packageInfo)
	for _, pkgInfos := range headersByKernelVersion {
		for idx := 0; idx < len(pkgInfos) && pkgInfos[idx].packageVersion == pkgInfos[0].packageVersion; idx += 1 {
			if !equalPackagePool(pkgInfos[0].url, pkgInfos[idx].url) {
				return nil, errors.Errorf("invalid mixture of package pools for package version %s: %s, %s", pkgInfos[0].packageVersion, pkgInfos[0].url, pkgInfos[idx].url)
			}
			headers[pkgInfos[0].kernelVersion] = append(headers[pkgInfos[0].kernelVersion], pkgInfos[idx])
		}
	}

	packageGroups := make([][]string, 0, len(headers))

	for version, headerPkgs := range headers {
		if len(headerPkgs) == 1 {
			continue
		}
		if len(headerPkgs) > 2 {
			return nil, errors.Errorf("invalid number of header packages for kernel version %s: %+v", version, headerPkgs)
		}

		var kbuildCandidates []packageInfo
		for _, headerPkg := range headerPkgs {
			kbuildPkg, ok := kbuildsByPackageVersion[headerPkg.packageVersion]
			if !ok {
				continue
			}
			if equalPackagePool(headerPkg.url, kbuildPkg.url) {
				kbuildCandidates = append(kbuildCandidates, kbuildPkg)
			}
		}

		if len(kbuildCandidates) == 0 {
			sepIndices := versionSepRegex.FindAllStringIndex(version, -1)
			kbuildPkgs, ok := kbuildsByKernelVersion[version]
			for !ok && len(sepIndices) > 0 {
				lastSepIdx := sepIndices[len(sepIndices)-1][0]
				sepIndices = sepIndices[:len(sepIndices)-1]
				kbuildPkgs, ok = kbuildsByKernelVersion[version[:lastSepIdx]]
			}
			if ok {
				for _, kbuildPkg := range kbuildPkgs {
					if equalPackagePool(headerPkgs[0].url, kbuildPkg.url) {
						kbuildCandidates = append(kbuildCandidates, kbuildPkg)
					}
				}
			}
		}

		if len(kbuildCandidates) == 0 {
			return nil, errors.Errorf("failed to find kbuild package for kernel version %s: candidates are %+v", version, kbuildsByKernelVersion)
		}

		sort.Slice(kbuildCandidates, func(i, j int) bool {
			return versionLess(kbuildCandidates[j].packageVersion, kbuildCandidates[i].packageVersion)
		})

		allPackages := make([]string, 0, 3)
		allPackages = append(allPackages, kbuildCandidates[0].url)
		for _, headerPkg := range headerPkgs {
			allPackages = append(allPackages, headerPkg.url)
		}

		packageGroups = append(packageGroups, allPackages)
	}

	return packageGroups, nil
}

// reformatPairs consumes a list of packages, and returns a list of package
// groups. Each package group is comprised of pairs of packages with the same
// version string. Packages with newer revisions will replace older revisions.
//
// For example: (Notice that the ".40" revision was dropped in favor of the ".50".)
// [4.4.0-1031.40_amd64, 4.4.0-1031.40_all, 4.4.0-1031.50_amd64, 4.4.0-1031.50_all, 4.4.0-1069.79_amd64, 4.4.0-1069.79_all] →
// [[4.4.0-1031.50_amd64, 4.4.0-1031.50_all], [4.4.0-1069.79_amd64, 4.4.0-1069.79_all]]
func reformatPairs(packages []string) ([][]string, error) {
	type rev struct {
		packages []string
		revision int
	}

	var (
		manifests = make([][]string, 0, len(packages)/2)
		versions  = make(map[string]rev)
	)

	for _, pkg := range packages {
		matches := reVersion.FindStringSubmatch(pkg)
		// Matches should have exactly 3 items, the full match, the version,
		// and the revision number.
		// Ex: {"4.4.0-1006.6", "4.4.0-1006", "6"}
		if len(matches) != 3 {
			return nil, fmt.Errorf("regex failed to match")
		}

		version := matches[1]
		revision, err := strconv.Atoi(matches[2])
		if err != nil {
			panic(err)
		}

		r, found := versions[version]

		switch {
		case found && r.revision > revision:
			break
		case found && r.revision == revision:
			r.packages = append(r.packages, pkg)
		case found && r.revision < revision:
			r = rev{[]string{pkg}, revision}
		case !found:
			r = rev{[]string{pkg}, revision}
		}

		versions[version] = r
	}

	for ver, rev := range versions {
		// Sanity check, there should always be a pair of packages.
		if len(rev.packages) != 2 {
			return nil, fmt.Errorf("version %q (rev %d): unpaired package %v", ver, rev.revision, rev.packages)
		}

		manifests = append(manifests, rev.packages)
	}

	return manifests, nil
}

// reformatSingle consumes a list of packages, and returns a list of package
// groups. Each package group is comprised of a single input package.
//
// For example:
// [a, b, c] → [[a], [b], [c]]
func reformatSingle(packages []string) ([][]string, error) {
	var sets = make([][]string, 0, len(packages))

	for _, pkg := range packages {
		set := []string{pkg}
		sets = append(sets, set)
	}

	return sets, nil
}
