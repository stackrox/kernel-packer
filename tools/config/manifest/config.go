package manifest

import (
	"crypto/sha256"
	"fmt"
	"io/ioutil"
	"path/filepath"
	"sort"

	"github.com/fatih/color"
	"github.com/pkg/errors"
	"gopkg.in/yaml.v2"
)

// Manifest represents a map of Builder instances.
type Manifest map[string]Builder

// Builder represents a single builder configuration. This captures all kernel
// versions that can be produced by the given type.
type Builder struct {
	Kind      string   `yaml:"type"`
	Packages  []string `yaml:"packages"`
	Bundle    string   `yaml:"bundle,omitempty"`
	NodeIndex int      `yaml:"nodeIndex,omitempty"`
}

// Add adds a Builder with the given kind and packages to the Manifest under an
// id derived by checksumming the given set of packages.
func (m Manifest) Add(kind string, packages []string) {
	var id = checksumStrings(packages)
	m[id] = Builder{
		Kind:     kind,
		Packages: packages,
	}
}

// Add adds a Builder to the Manifest under an id derived by checksumming the
// set of packages in the Builder.
func (m Manifest) AddBuilder(builder Builder) {
	id := checksumStrings(builder.Packages)
	m[id] = builder
}

// SortedIDs returns a list of all manifest ids, sorted in alphabetical order.
func (m Manifest) SortedIDs() []string {
	ids := make([]string, 0, len(m))
	for key := range m {
		ids = append(ids, key)
	}
	sort.Strings(ids)
	return ids
}

// New returns an initialized builder
func New() Manifest {
	return make(Manifest)
}

// Load reads the given filename as yaml and parses the content into a list of
// Manifest.
func Load(filename string) (Manifest, error) {
	body, err := ioutil.ReadFile(filename)
	if err != nil {
		return nil, err
	}

	var builders map[string]Builder
	if err := yaml.UnmarshalStrict(body, &builders); err != nil {
		return nil, err
	}

	return builders, nil
}

// Save writes the given manifest as yaml to the given filename.
func Save(mf Manifest, filename string) error {
	body, err := yaml.Marshal(mf)
	if err != nil {
		return errors.Wrap(err, "failed to marshal cache object")
	}

	if err := ioutil.WriteFile(filename, body, 0644); err != nil {
		return errors.Wrap(err, "failed to write cache file")
	}

	return nil
}

// Combine aggregates all of the given manifests together into one single
// manifest.
func Combine(caches ...Manifest) Manifest {
	combined := New()
	for _, cache := range caches {
		for id, builder := range cache {
			combined[id] = builder
		}
	}
	return combined
}

// CombineFiles aggregates all of the given manifest files together into one
// single manifest.
func CombineFiles(filenames []string) (Manifest, error) {
	fragments := make([]Manifest, len(filenames))
	for index, filename := range filenames {
		fragment, err := Load(filename)
		if err != nil {
			return nil, errors.Wrap(err, "failed to load cache fragment")
		}
		if filepath.Base(filename) != "cache.yml" {
			for id, mf := range fragment {
				color.Green("Built bundle %s on node %d with id %s\n", mf.Bundle, mf.NodeIndex, id)
			}
		}
		fragments[index] = fragment
	}
	return Combine(fragments...), nil
}

// CombineDir aggregates all of the manifest .yml files inside of the given
// directory together into one single manifest.
func CombineDir(directory string) (Manifest, error) {
	var pattern = filepath.Join(directory, "*.yml")
	matches, err := filepath.Glob(pattern)
	if err != nil {
		return nil, errors.Wrap(err, "bad glob pattern")
	}
	return CombineFiles(matches)
}

// checksumStrings returns a consistent hash for the given set of package names.
func checksumStrings(packages []string) string {
	var (
		s = sha256.New()
	)

	sortedPackages := append([]string{}, packages...)
	sort.Strings(sortedPackages)
	for _, pkg := range sortedPackages {
		s.Write([]byte(pkg))
	}

	return fmt.Sprintf("%x", s.Sum(nil))
}
