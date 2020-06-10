package reformatters

import (
	"regexp"
	"strconv"
	"strings"
)

var (
	numericVersionRegex = regexp.MustCompile(`^\d+(?:\.\d+)*`)
)

func versionLess(versionA, versionB string) bool {
	numericA := numericVersionRegex.FindString(versionA)
	numericB := numericVersionRegex.FindString(versionB)

	if numericA == "" || numericB == "" {
		return numericB != ""
	}

	partsA := strings.Split(numericA, ".")
	partsB := strings.Split(numericB, ".")

	minNumParts := len(partsA)
	if len(partsB) < minNumParts {
		minNumParts = len(partsB)
	}

	for i := 0; i < minNumParts; i++ {
		partA, _ := strconv.Atoi(partsA[i])
		partB, _ := strconv.Atoi(partsB[i])
		if partA != partB {
			return partA < partB
		}
	}
	return len(partsA) < len(partsB)
}
