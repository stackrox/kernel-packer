package cache

import (
	"fmt"
	"io/ioutil"
	"path/filepath"
	"strings"

	"github.com/pkg/errors"
	"gopkg.in/yaml.v2"
)

type (
	Cache map[string]Entry

	Entry struct {
		Version  string   `yaml:"version"`
		Type     string   `yaml:"type"`
		Packages []string `yaml:"packages"`
		URL      string   `yaml:"url"`
		Git      string   `yaml:"git"`
		Artifact string   `yaml:"artifact"`
	}
)

func (c Cache) Contains(id string) bool {
	_, found := c[id]
	return found
}

func Load(filename string) (*Cache, error) {
	body, err := ioutil.ReadFile(filename)
	if err != nil {
		return nil, errors.Wrap(err, "failed to read cache file")
	}

	var cfg Cache
	if err := yaml.UnmarshalStrict(body, &cfg); err != nil {
		return nil, errors.Wrap(err, "failed to unmarshal cache file")
	}

	return &cfg, nil
}

func Save(cfg *Cache, filename string) error {
	body, err := yaml.Marshal(cfg)
	if err != nil {
		return errors.Wrap(err, "failed to marshal cache object")
	}

	if err := ioutil.WriteFile(filename, body, 0644); err != nil {
		return errors.Wrap(err, "failed to write cache file")
	}

	return nil
}

func Combine(caches ...*Cache) *Cache {
	combined := make(Cache)
	for _, cache := range caches {
		for id, entry := range *cache {
			combined[id] = entry
		}
	}
	return &combined
}

func CombineFiles(filenames []string) (*Cache, error) {
	fragments := make([]*Cache, len(filenames), len(filenames))
	for index, filename := range filenames {
		fragment, err := Load(filename)
		if err != nil {
			return nil, errors.Wrap(err, "failed to load cache fragment")
		}
		fragments[index] = fragment
	}
	return Combine(fragments...), nil
}

func CombineDir(directory string) (*Cache, error) {
	var pattern = fmt.Sprintf("%s/*.yml", strings.TrimSuffix(directory, "/"))
	matches, err := filepath.Glob(pattern)
	if err != nil {
		return nil, errors.Wrap(err, "bad glob pattern")
	}
	return CombineFiles(matches)
}
