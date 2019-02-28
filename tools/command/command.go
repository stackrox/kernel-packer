package command

import (
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
)

// Run will exec the given command and stream all output (stdout and stderr)
// back to the current terminal.
func Run(name string, arg ...string) error {
	cmd := exec.Command(name, arg...)

	stdout, err := cmd.StdoutPipe()
	if err != nil {
		return err
	}

	stderr, err := cmd.StderrPipe()
	if err != nil {
		return err
	}

	go io.Copy(os.Stdout, stdout)
	go io.Copy(os.Stderr, stderr)

	return cmd.Run()
}

func DockerCommand(checksum string, distroName string, outputDir string, packages []string) (string, []string, error) {
	var cmd = "docker"
	var args = []string{
		"run",
		"--privileged",
		"--rm",
		"-t",
	}

	if len(packages) == 0 {
		return "", nil, errors.New("no packages given")
	}

	if !filepath.IsAbs(outputDir) {
		return "", nil, errors.New("output directory is not an absolute path")
	}

	// Add a series of read-only volume mappings for each of the given packages.
	for index, pkg := range packages {
		if !filepath.IsAbs(pkg) {
			return "", nil, errors.New("package is not an absolute path")
		}
		var volumeMapping = fmt.Sprintf("%s:/input/package-%d:ro", pkg, index)
		args = append(args, "-v", volumeMapping)
	}

	// Add a single volume mapping for the output directory.
	args = append(args, "-v", fmt.Sprintf("%s:/output", outputDir))

	// Add the Docker image name, distro name, and output directory alias
	args = append(args, "repackage:latest", checksum, distroName, "/output")

	// Add a series of package names, same as the volume aliases.
	for index := range packages {
		args = append(args, fmt.Sprintf("/input/package-%d", index))
	}

	return cmd, args, nil
}
