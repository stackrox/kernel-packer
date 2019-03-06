package command

import (
	"fmt"
	"testing"

	"github.com/stretchr/testify/require"
)

func Test(t *testing.T) {
	tests := []struct {
		title        string
		checksum     string
		distro       string
		outputDir    string
		packages     []string
		err          string
		expectedArgs []string
	}{
		{
			title: "empty packages",
			err:   "no packages given",
		},
		{
			title:     "relative output dir",
			outputDir: ".build-data/bundles",
			packages:  []string{"fake"},
			err:       "output directory is not an absolute path",
		},
		{
			title:     "relative package",
			outputDir: "/.build-data/bundles",
			packages:  []string{"package.rpm"},
			err:       "package is not an absolute path",
		},
		{
			title:     "one relative package",
			outputDir: "/.build-data/bundles",
			packages:  []string{"/package-a.rpm", "package-b.rpm", "/package-c.rpm"},
			err:       "package is not an absolute path",
		},
		{
			title:     "single package",
			checksum:  "sha",
			distro:    "redhat",
			outputDir: "/.build-data/bundles",
			packages:  []string{"/package.rpm"},
			expectedArgs: []string{
				"run", "--privileged", "--rm", "-t",
				"-v", "/package.rpm:/input/package-0:ro",
				"-v", "/.build-data/bundles:/output",
				"repackage:latest", "sha", "redhat", "/output", "/input/package-0",
			},
		},
		{
			title:     "multiple package",
			checksum:  "sha",
			distro:    "redhat",
			outputDir: "/.build-data/bundles",
			packages: []string{
				"/package-a.rpm",
				"/dir/package-b.rpm",
				"/package-c.rpm",
			},
			expectedArgs: []string{
				"run", "--privileged", "--rm", "-t",
				"-v", "/package-a.rpm:/input/package-0:ro",
				"-v", "/dir/package-b.rpm:/input/package-1:ro",
				"-v", "/package-c.rpm:/input/package-2:ro",
				"-v", "/.build-data/bundles:/output",
				"repackage:latest", "sha", "redhat", "/output",
				"/input/package-0",
				"/input/package-1",
				"/input/package-2",
			},
		},
	}

	for index, test := range tests {
		name := fmt.Sprintf("%d %s", index+1, test.title)
		t.Run(name, func(t *testing.T) {

			actualCmd, actualArgs, actualErr := DockerCommand(test.checksum, test.distro, test.outputDir, test.packages)

			if test.err != "" {
				require.EqualError(t, actualErr, test.err)
				return
			} else {
				require.NoError(t, actualErr)
			}

			require.Equal(t, "docker", actualCmd)

			require.Equal(t, test.expectedArgs, actualArgs)
		})
	}
}
