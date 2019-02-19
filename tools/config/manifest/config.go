package manifest

import (
	"crypto/sha256"
	"fmt"
	"io/ioutil"
	"sort"

	"gopkg.in/yaml.v2"
)

// Builders represents a named map of Builder instances.
type Builders map[string]Builder

// Builder represents a single builder configuration. This captures all kernel
// versions that can be produced by the given type.
type Builder struct {
	Description string              `yaml:"description"`
	Kind        string              `yaml:"type"`
	Packages    map[string][]string `yaml:"packages"`
}

// Manifest represents a fully self-contained kernel build unit. All
// information required for building a single kernel module is captured in a
// Manifest instance.
type Manifest struct {
	Builder     string
	Description string
	Packages    []string
	Kind        string
	Build       bool
	Id          string
	URL         string
}

// Load reads the given filename as yaml and parses the content into a list of
// Builders.
func Load(filename string) (Builders, error) {
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

// ChecksumPackageNames returns a consistent hash for the given set of package names.
func ChecksumPackageNames(packages []string) string {
	var (
		s = sha256.New()
	)

	sort.Strings(packages)
	for _, pkg := range packages {
		s.Write([]byte(pkg))
	}

	return fmt.Sprintf("%x", s.Sum(nil))
}

func Simplify(s string) string {
	var result = ""

	for _, rune := range s {
		switch {
		case 'a' <= rune && rune <= 'z':
			fallthrough
		case 'A' <= rune && rune <= 'Z':
			fallthrough
		case '0' <= rune && rune <= '9':
			fallthrough
		case '_' == rune || '.' == rune || '-' == rune:
			result += string(rune)
		default:
			result += "-"
		}
	}

	return result
}
