package reformat

import (
	"io/ioutil"

	"github.com/pkg/errors"
	"gopkg.in/yaml.v2"
)

type (
	Config []Entry

	Entry struct {
		Name        string `yaml:"name"`
		Description string `yaml:"description"`
		Type        string `yaml:"type"`
		Reformat    string `yaml:"reformat"`
		Version     string `yaml:"version"`
		File        string `yaml:"file"`
		PackerImage string `yaml:"packerImage,omitempty"`
	}
)

func Load(filename string) (*Config, error) {
	body, err := ioutil.ReadFile(filename)
	if err != nil {
		return nil, errors.Wrap(err, "failed to read reformat config file")
	}

	var cfg Config
	if err := yaml.UnmarshalStrict(body, &cfg); err != nil {
		return nil, errors.Wrap(err, "failed to unmarshal reformat config file")
	}

	return &cfg, nil
}
