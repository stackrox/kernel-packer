package main

import (
	"flag"
	"fmt"
	"math/rand"
	"os"
	"strconv"

	"github.com/fatih/color"
	"github.com/pkg/errors"

	"github.com/stackrox/kernel-packer/tools/config/cache"
	"github.com/stackrox/kernel-packer/tools/config/manifest"
)

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

var (
	nodeCount = envInt("CIRCLE_NODE_TOTAL", 1)
	nodeIndex = envInt("CIRCLE_NODE_INDEX", 0)
)

func main() {
	if err := mainCmd(); err != nil {
		fmt.Fprintf(os.Stderr, "build: %s\n", err.Error())
		os.Exit(1)
	}
}

func mainCmd() error {
	var (
		flagManifest  = flag.String("manifest", "", "Path to build manifest file.")
		flagCacheFile = flag.String("cache-file", "", "Path to build cache file.")
		flagCacheDir  = flag.String("cache-dir", "", "Path to build cache fragment dir.")
		flagAction    = flag.String("action", "build", `Action to take. (one of "build" or "combine")`)
	)
	flag.Parse()

	switch *flagAction {
	case "build":
		return buildCmd(*flagManifest, *flagCacheFile, *flagCacheDir)

	case "combine":
		return combineCmd(*flagCacheFile, *flagCacheDir)

	default:
		return errors.New("unknown action")
	}

	return nil
}

func buildCmd(manifestFile string, cacheFile string, cacheDir string) error {
	builders, err := manifest.Load(manifestFile)
	if err != nil {
		return errors.Wrap(err, "failed to load build builders")
	}

	cc, err := cache.Load(cacheFile)
	if err != nil {
		return errors.Wrap(err, "failed to load cache file")
	}

	var (
		totalPass   int
		totalFail   int
		totalCach   int
		totalSkip   int
		failureRate = 0.3
		manifests   = builders.Manifests()
	)

	// Mark any manifest that exists in the cache as not to be built.
	for index, manifest := range manifests {
		if cc.Contains(manifest.Id) {
			manifests[index].Build = false
			totalCach++
		} else {
			manifests[index].Build = true
		}
	}

	// Mark any manifest that does not fall on this node as not to be built.
	var count int
	for index, manifest := range manifests {
		if !manifest.Build {
			continue
		}
		if count%nodeCount == nodeIndex {
			manifests[index].Build = true
		} else {
			manifests[index].Build = false
			totalSkip++
		}
		count++
	}

	// Build all manifests
	for _, manifest := range manifests {
		if !manifest.Build {
			color.Blue("[SKIP] build manifest %s %s (%s)\n", manifest.Builder, manifest.Kind, manifest.Id)
			continue
		}

		// For now, roll the dice and "fake" builds passing or failing.
		var success = rand.Float64() > failureRate

		if success {
			color.Green("[PASS] built manifest %s %s (%s)\n", manifest.Builder, manifest.Kind, manifest.Id)
			totalPass++
			if err := saveCacheFragment(manifest, cacheDir); err != nil {
				fmt.Printf("       Failed to save cache fragment: %v\n", err)
			}
		} else {
			color.Red("[FAIL] to build manifest %s %s (%s)\n", manifest.Builder, manifest.Kind, manifest.Id)
			totalFail++
		}
	}

	color.White("[DONE] CASH:%d IGNR:%d PASS:%d FAIL:%d TOTL:%d\n", totalCach, totalSkip, totalPass, totalFail, totalPass+totalFail+totalSkip+totalCach)
	return nil
}

func combineCmd(cacheFile string, cacheDir string) error {
	cc, err := cache.Load(cacheFile)
	if err != nil {
		return errors.Wrap(err, "failed to load cache file")
	}

	fragments, err := cache.CombineDir(cacheDir)
	if err != nil {
		return errors.Wrap(err, "failed to load cache fragment")
	}
	combined := cache.Combine(cc, fragments)
	if err := cache.Save(combined, cacheFile); err != nil {
		return errors.Wrap(err, "failed to save combined cache")
	}

	return nil
}

func saveCacheFragment(manifest *manifest.Manifest, cacheDir string) error {
	cf := cache.Cache{
		manifest.Id: cache.Entry{
			Packages: manifest.Packages,
			Type:     manifest.Builder + "-" + manifest.Kind,
			Version:  manifest.Version,
			URL:      manifest.URL,
			Git:      manifest.Git,
			Artifact: manifest.Artifact,
		},
	}
	filename := fmt.Sprintf("%s/fragment-%s.yml", cacheDir, manifest.Id)
	if err := cache.Save(&cf, filename); err != nil {
		return errors.Wrap(err, "failed to save cache fragment")
		//fmt.Printf("       Failed to save cache fragment: %v\n", err)
	}
	return nil
}
