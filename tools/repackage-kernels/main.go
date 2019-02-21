package main

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strconv"

	"github.com/fatih/color"
	"github.com/pkg/errors"

	"github.com/stackrox/kernel-packer/tools/config/manifest"
)

var (
	// nodeCount is the total number if CircleCI build nodes in the current job.
	nodeCount = envInt("CIRCLE_NODE_TOTAL", 1)

	// nodeIndex is which CircleCI build node the current job is running on.
	nodeIndex = envInt("CIRCLE_NODE_INDEX", 0)
)

func main() {
	if err := mainCmd(); err != nil {
		fmt.Fprintf(os.Stderr, "repackage-kernels: %s\n", err.Error())
		os.Exit(1)
	}
}

func mainCmd() error {
	var (
		flagManifest = flag.String("manifest", "", "Path to build manifest file.")
		flagCacheDir = flag.String("cache-dir", "", "Path to build cache directory.")
		flagAction   = flag.String("action", "build", `Action to take. (one of "build" or "combine")`)
	)
	flag.Parse()

	switch *flagAction {
	case "build":
		return buildCmd(*flagManifest, *flagCacheDir)

	case "combine":
		return combineCmd(*flagCacheDir)

	default:
		return errors.New("unknown action")
	}
}

// buildCmd is the action that is run when the flag -action=build is used.
// This action will build all possible manifests, except for the ones that
// already exist in the build cache, or fall on a different CircleCI build node.
func buildCmd(manifestFile string, cacheDir string) error {
	var (
		cacheFile = filepath.Join(cacheDir, "cache.yml")
		count     int
	)

	// buildCache is a record of all builds, that were successfully built.
	buildCache, err := manifest.Load(cacheFile)
	if err != nil {
		return errors.Wrap(err, "failed to load build cache")
	}

	// buildManifest is a record of all possible builds.
	buildManifest, err := manifest.Load(manifestFile)
	if err != nil {
		return errors.Wrap(err, "failed to load build manifest")
	}

	for _, id := range buildManifest.SortedIDs() {
		// Skip this build if it already exists in the cache.
		if _, found := buildCache[id]; found {
			color.Blue("[SKIP] [%s] | build has been cached\n", id)
			continue
		}

		// Skip this build if it does not fall on this (CircleCI) build node.
		if count%nodeCount != nodeIndex {
			color.Blue("[SKIP] [%s] | build falls on another node\n", id)
			count++
			continue
		} else {
			count++
		}

		var (
			builder = buildManifest[id]
			err     = build(builder, id)
		)

		// This build failed. Report it and move along.
		if err != nil {
			color.Red("[FAIL] [%s] | %v\n", id, err)
			color.Red("       ↳ %v\n", err)
			continue
		}

		// This build succeeded! Save a cache fragment for this specific id.
		color.Green("[PASS] [%s]\n", id)
		if err := saveCacheFragment(builder, id, cacheDir); err != nil {
			fmt.Printf("       Failed to save cache fragment: %v\n", err)
		}
	}

	return nil
}

// combineCmd is the action that is run when the flag -action=combine is used.
// This action combines the contents of the files in the cache directory into
// one single cache file.
func combineCmd(cacheDir string) error {
	var cacheFile = filepath.Join(cacheDir, "cache.yml")

	// Load all of the little cache fragments from the cache directory.
	fragments, err := manifest.CombineDir(cacheDir)
	if err != nil {
		return errors.Wrap(err, "failed to load cache fragment")
	}

	// Combine all of the little cache fragments together into one single
	// cache, and save it back to the cache directory.
	combined := manifest.Combine(fragments)
	err = manifest.Save(combined, cacheFile)
	return errors.Wrap(err, "failed to save combined cache")
}

// build runs a repackage build for the given manifest.
func build(builder manifest.Builder, id string) error {
	return errors.New("not yet implemented")
}

// saveCacheFragment writes a cache fragment inside of the cache directory.
func saveCacheFragment(builder manifest.Builder, id string, cacheDir string) error {
	var (
		filename = filepath.Join(cacheDir, fmt.Sprintf("fragment-%s.yml", id))
		mf       = manifest.New()
	)

	// A cache fragment contains a single entry.
	mf.Add(builder.Kind, builder.Packages)

	err := manifest.Save(mf, filename)
	return errors.Wrap(err, "failed to save cache fragment")
}

// envInt looks up the given environment variable and returns its value as an
// integer. If the variable is not set, or contains an invalid value, a
// fallback value is returned.
func envInt(key string, fallback int) int {
	value, found := os.LookupEnv(key)
	if !found {
		return fallback
	}
	number, err := strconv.Atoi(value)
	if err != nil {
		return fallback
	}
	return number
}
