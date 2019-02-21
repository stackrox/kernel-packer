package manifest

import (
	"crypto/sha256"
	"fmt"
	"io/ioutil"
	"sort"

	"gopkg.in/yaml.v2"
)

// Manifest represents a map of Builder instances.
type Manifest map[string]Builder

// Builder represents a single builder configuration. This captures all kernel
// versions that can be produced by the given type.
type Builder struct {
	Kind     string   `yaml:"type"`
	Packages []string `yaml:"packages"`
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

// checksumStrings returns a consistent hash for the given set of package names.
func checksumStrings(packages []string) string {
	var (
		s = sha256.New()
	)

	sort.Strings(packages)
	for _, pkg := range packages {
		s.Write([]byte(pkg))
	}

	return fmt.Sprintf("%x", s.Sum(nil))
}
