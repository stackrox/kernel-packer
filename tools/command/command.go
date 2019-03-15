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

	pkgDir := filepath.Dir(packages[0])
	for _, pkg := range packages {
		if !filepath.IsAbs(pkg) {
			return "", nil, errors.New("package is not an absolute path")
		}
		if pkgDir != filepath.Dir(pkg) {
			return "", nil, errors.New("packages are not all in the same directory")
		}
	}

	// Add a read-only volume mapping for directory containing the given packages.
	args = append(args, "-v", fmt.Sprintf("%s:/input:ro", pkgDir))

	// Add a single volume mapping for the output directory.
	args = append(args, "-v", fmt.Sprintf("%s:/output", outputDir))

	// Add the Docker image name, distro name, and output directory alias
	args = append(args, "repackage:latest", checksum, distroName, "/output")

	// Add a series of package names, same as the volume aliases.
	for _, pkg := range packages {
		args = append(args, fmt.Sprintf("/input/%s", filepath.Base(pkg)))
	}

	return cmd, args, nil
}
