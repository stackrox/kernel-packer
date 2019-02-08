package reformat

import (
	"io/ioutil"

	"github.com/pkg/errors"
	"gopkg.in/yaml.v2"
)

type (
	Config []Entry

	Entry struct {
		Name        string `yml:"name"`
		Description string `yml:"description"`
		Type        string `yml:"type"`
		Reformat    string `yml:"reformat"`
		Version     string `yml:"version"`
		File        string `yml:"file"`
	}
)

func Load(filename string) (*Config, error) {
	body, err := ioutil.ReadFile(filename)
	if err != nil {
		return nil, errors.Wrap(err, "failed to read cache file")
	}

	var cfg Config
	if err := yaml.UnmarshalStrict(body, &cfg); err != nil {
		return nil, errors.Wrap(err, "failed to unmarshal cache file")
	}

	return &cfg, nil
}
